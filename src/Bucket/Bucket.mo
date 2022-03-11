import Array "mo:base/Array";
import Blob  "mo:base/Blob";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat  "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import SM "mo:base/ExperimentalStableMemory";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import SHA256 "SHA256";
import Hex "Hex";
import Types "Types";

module {

    public class Bucket() {
        private type Chunk              = Types.Chunk;
        private type Asset              = Types.Asset;
        private type AssetExt           = Types.AssetExt;
        private type AssetBuffer        = Types.AssetBuffer;
        private type PUT                = Types.PUT;
        private type GET                = Types.GET;
        private type DataErr            = Types.DataErr;
        private let CYCLE_LIMIT             = 20_000_000_000_000;
        private let PAGE_SIZE               = 65536;
        private let THRESHOLD               = 6442450944;
        private let MAX_PAGE_NUMBER : Nat32 = 98304;
        private let MAX_UPDATE_SIZE         = 1992295;
        private let MAX_QUERY_SIZE          = 3144728;
        private var offset                  = 0;
        private var key_name_entries : [var (Text, Text)]  = [var];
        private var asset_entries : [var (Text, Asset)]    = [var];
        private var key_name_map     = TrieMap.fromEntries<Text, Text>(key_name_entries.vals(), Text.equal, Text.hash);
        private var asset_map        = TrieMap.fromEntries<Text, Asset>(asset_entries.vals(), Text.equal, Text.hash);
        private var asset_buffer_map = HashMap.HashMap<Text, AssetBuffer>(10, Text.equal, Text.hash); 

        // 可用内存
        public func getAvailableStableMemory() : Nat {
            _getAvailableStableMemory()
        };
        // 获取数据
        public func get(g : GET) : Result.Result<Blob, DataErr> {
            switch (_get(g)) {
                case(#ok(data)) { return #ok(data) };
                case(#err(err)) { return #err(err) };
            }
        };

        // 获取所有文件元信息
        public func getAssetExts(caller : Principal) : [AssetExt] {
            _getAssetExts(caller)
        };

        // 获取某一个文件的元信息
        public func getAssetExtByKey(file_key : Text, caller : Principal) : Result.Result<AssetExt, DataErr> {
            switch (_getAssetExtByKey(file_key, caller)) {
                case(#ok(ext)) { return #ok(ext) };
                case(#err(err)) { return #err(err) };
            }
        };

        // 上传文件块
        public func put(p : PUT, caller : Principal) : Result.Result<AssetExt, DataErr> {
            switch (_put(p, caller)) {
                case (#ok(ext)) { #ok(ext) };
                case (#err(err)) { #err(err) };
            }
        };

        // 清空整个Bucket，remake了
        public func clear() : Text {
            _clear()
        };

        // 更新前存entries
        public func preUpgrade() : Text {
            _preUpgrade()
        };

        private func _getAvailableStableMemory() : Nat{
            THRESHOLD - offset
        };

        private func _getStableMemory(field : (Nat, Nat)) : Blob {
            SM.loadBlob(Nat32.fromNat(field.0), field.1)
        };

        private func _get(g : GET) : Result.Result<Blob, DataErr> {
            switch (asset_map.get(g.file_key)) {
                case (null) { return #err(#FileKeyErr) };
                case (?asset) {
                    if (g.flag >= asset.page_field.size()) { return #err(#FlagErr) }
                    else { return #ok(_getStableMemory(asset.page_field[g.flag])) }
                };
            }
        };

        private func _assetExt(asset : Asset, upload_status : Bool, caller: Principal) : AssetExt {
            {
                bucket_id        = caller;
                file_key         = asset.file_key;
                file_name        = asset.file_name;
                file_extension   = asset.file_extension;
                total_size       = asset.total_size;
                upload_status    = upload_status;
                need_query_times = asset.page_field.size();
            }
        };

        private func _getAssetExts(caller : Principal) : [AssetExt] {
            let asset_ext : AssetExt = {
                bucket_id      = caller;
                file_key       = "";
                file_name      = "";
                file_extension = "";
                total_size     = 0;
                upload_status  = false;
                need_query_times = 0; 
            };
            var res = Array.init<AssetExt>(asset_map.size(), asset_ext);
            if (asset_map.size() > 0) {
                var i : Nat = 0;
                for (asset in asset_map.vals()) {
                    res[i] := _assetExt(asset, true, caller);
                    i += 1;
                };
            };
            Array.freeze<AssetExt>(res)
        };

        private func _getAssetExtByKey(file_key : Text, caller : Principal) : Result.Result<AssetExt, DataErr> {
            switch (asset_map.get(file_key)) {
                case (null) { #err(#FileKeyErr) };
                case (?asset) { return #ok(_assetExt(asset, true, caller)) };
            }
        };


        // 检查total_size大小
        private func _inspectSize(total_size : Nat) : Result.Result<Nat, DataErr> {
            if (total_size == 0) { return #err(#BlobSizeError) };
            if (total_size <= _getAvailableStableMemory()) { #ok(total_size) } else { #err(#MemoryInsufficient) };
        };

        // 检查chunk大小
        private func _inspectChunkSize(data : Blob, chunk_number : Nat, chunk_order : Nat, total_size : Nat) : Result.Result<Nat, DataErr> {
            var size : Nat = data.size();
            if (size == 0 or total_size == 0) { return #err(#BlobSizeError) };

            if (chunk_order + 1 == chunk_number and size + chunk_order * MAX_UPDATE_SIZE > total_size) { return #err(#BlobSizeError) }
            else if (size != MAX_UPDATE_SIZE) { return #err(#BlobSizeError) }; 

            if (size <= _getAvailableStableMemory()) { #ok(size) } else { #err(#MemoryInsufficient) };
        };

        private func _put(p : PUT, caller: Principal) : Result.Result<AssetExt, DataErr> {
            switch (asset_map.get(p.file_key)) {
                case (?asset) { return #ok(_assetExt(asset, true, caller)) };
                case (_) { };
            };
            switch (asset_buffer_map.get(p.file_key)) {
                case (?asset_buffer) { };
                case (_) {
                    switch (_readPageField(p.total_size)) {
                        case (#ok(read_page_field)) {
                            // 初始化生成asset_buffer
                            let asset_buffer = {
                                chunk_number     = p.chunk_number;
                                total_size       = p.total_size;
                                digest           = Array.init<Nat8>(p.chunk_number*32, 0);
                                read_page_field  = read_page_field;
                                write_page_field = _writePageField(read_page_field, p.chunk_number, p.total_size);
                                wrote_page       = Array.init<Bool>(p.chunk_number, false);
                                var received     = 0;
                            };
                            asset_buffer_map.put(p.file_key, asset_buffer);
                        };
                        case (#err(info)) { return #err(info) };
                    };
                };
            };
            switch (_inspectChunkSize(p.chunk.data, p.chunk_number, p.chunk_order, p.total_size)) {
                case (#ok(size)) { return _upload(p.file_key, p.file_name, p.file_extension, p.chunk, p.chunk_number, p.chunk_order, p.total_size, caller) };
                case (#err(info)) { return #err(info) };
            };
        };

        // upload时根据分配好的write_page以vals的形式写入数据
        private func _storageData(write_page : [(Nat, Nat)], data : Blob) {
            var index : Nat = 0;
            var page_start = write_page[index].0;
            var page_size  = write_page[index].1;
            var ptr = page_start;
            for (byte in data.vals()) {
                if (ptr == page_start + page_size) {
                    index += 1;
                    assert(index < write_page.size());
                    page_start := write_page[index].0;
                    page_size := write_page[index].1;
                    ptr := page_start;
                };
                SM.storeNat8(Nat32.fromNat(ptr), byte);
                ptr += 1;
            };
        };

        // digest信息聚合
        private func _appendDigest(prev : [var Nat8], new : [Nat8], order : Nat) {
            var i = order * 32;
            for (num in new.vals()) {
                prev[i] := num;
                i += 1;
            };
        };

        private func _key(digests : [Nat8]) : Text {
            Hex.encode(SHA256.sha256(digests))
        };

        private func _upload(file_key : Text, file_name : Text, file_extension : Text, chunk : Chunk, chunk_number : Nat, chunk_order : Nat, total_size : Nat, caller: Principal) : Result.Result<AssetExt, DataErr> {
            switch (asset_buffer_map.get(file_key)) {
                case (null) { return #err(#FileKeyErr) };
                case (?asset_buffer) {
                    // 先判断该chunk是否写入
                    if (asset_buffer.wrote_page[chunk_order] == false) {
                        // 新chunk到达时，在wrote_page中在其位置标记为1，防止已写入的chunk又写入一遍
                        _appendDigest(asset_buffer.digest, chunk.digest, chunk_order);
                        asset_buffer.wrote_page[chunk_order] := true; 
                        asset_buffer.received += 1;
                        _storageData(asset_buffer.write_page_field[chunk_order], chunk.data);

                        // 当所有chunk收到时组装成asset
                        if (asset_buffer.received + 1 == asset_buffer.chunk_number) {
                            let asset : Asset = {
                                file_key  = _key(Array.freeze(asset_buffer.digest));
                                file_name = file_name;
                                file_extension = file_extension;
                                total_size = asset_buffer.total_size;
                                page_field = asset_buffer.read_page_field;
                            };
                            asset_map.put(asset.file_key, asset);
                            key_name_map.put(asset.file_key, file_name);
                            asset_buffer_map.delete(file_key);
                            Debug.print("Final Asset: " # debug_show(asset));
                            return #ok(_assetExt(asset, true, caller))
                        } else {
                            return #ok(_assetExt({
                                file_key  = file_key;
                                file_name = file_name;
                                file_extension = file_extension;
                                page_field = asset_buffer.read_page_field;
                                total_size = asset_buffer.total_size;
                            }, false, caller))
                        }
                    // 已经写入的chunk直接返回asset_ext
                    } else {
                        return #ok(_assetExt({
                            file_key  = file_key;
                            file_name = file_name;
                            file_extension = file_extension;
                            page_field = asset_buffer.read_page_field;
                            total_size = asset_buffer.total_size;
                        }, false, caller))
                    }
                };
            };
            #err(#FileKeyErr)
        };

        private func _clear() : Text {
            offset := 0;
            key_name_map := TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
            asset_map    := TrieMap.TrieMap<Text, Asset>(Text.equal, Text.hash);
            asset_buffer_map := HashMap.HashMap<Text, AssetBuffer>(10, Text.equal, Text.hash);
            return ("Clear Successfully.")
        };
        
        private func _appendArray(arr_1 : [var (Nat, Nat)], arr_2 : [var (Nat, Nat)]) : [var (Nat, Nat)] {
            switch (arr_1.size(), arr_2.size()) {
                case (0, 0) { [var] };
                case (_, 0) { arr_1 };
                case (0, _) { arr_2 };
                case (_, _) {
                    let res = Array.init<(Nat, Nat)>(arr_1.size() + arr_2.size(), (0, 0));
                    var i = 0;
                    for (e in arr_1.vals()) {
                        res[i] := arr_1[i];
                        i += 1;
                    };
                    for (e in arr_2.vals()) {
                        res[i] := arr_2[i - arr_1.size()];
                        i += 1;
                    };
                    res
                };
            }
        };

        // 获取需要grow的SM内存页数量
        private func _getStableMemoryPageNumber(size : Nat) : Nat32 {
            Nat32.fromNat(size / PAGE_SIZE + 1)
        };

        // grow大小为size的SM内存页
        private func _growStableMemoryPage(size : Nat) {
            let available_mem : Nat = Nat32.toNat(SM.size()) * PAGE_SIZE - offset;
            if (available_mem < size) {
                let need_allo_size : Nat = size - available_mem;
                let growPage : Nat32 = _getStableMemoryPageNumber(need_allo_size);
                if ((growPage + SM.size() <= MAX_PAGE_NUMBER)) {
                    ignore SM.grow(growPage);
                } else if ((growPage + SM.size() - 1 : Nat32) == MAX_PAGE_NUMBER) {
                    let newGrowPage : Nat32 = growPage - 1;
                    if (newGrowPage > 0) {
                        ignore SM.grow(newGrowPage);
                    };
                };
            };
        };

        // 文件预分配
        private func _readPageField(total_size : Nat) : Result.Result<[(Nat, Nat)], DataErr> {
            // 检查可用空间是否放得下文件
            switch (_inspectSize(total_size)) {
                case (#err(err)) { return #err(err); };
                case (#ok(info)) { };
            };

            var res : [var (Nat, Nat)] = [var];
            var start : Nat = offset;
            var ptr : Nat = start;
            _growStableMemoryPage(total_size);
            offset += total_size;
            
            label l loop {
                if (total_size <= MAX_QUERY_SIZE) {
                    res := [var (start, total_size)];
                    break l;
                } else if (ptr + MAX_QUERY_SIZE < start + total_size) {
                    res := _appendArray(res, [var (ptr, MAX_QUERY_SIZE)]);
                    ptr += MAX_QUERY_SIZE;
                } else {
                    res := _appendArray(res, [var (ptr, start + total_size - ptr)]);
                    break l;
                };
            };
            #ok(Array.freeze<(Nat, Nat)>(res));
        };

        // 获得第chunk_number个的write_page的大小，即第chunk_number个chunk中数据的大小
        private func _getWritePageSize(write_page_index : Nat, chunk_number : Nat, total_size : Nat) : Nat {
            if (write_page_index == (chunk_number - 1 : Nat)) {
                total_size - write_page_index * MAX_UPDATE_SIZE
            } else {
                MAX_UPDATE_SIZE
            }
        };

        //根据预分配好的read_page_field分成chunk_number个read_page，以便于将各chunk的数据写入对应的read_page中
        private func _writePageField(read_page_field : [(Nat, Nat)], chunk_number : Nat, total_size : Nat) : [[(Nat, Nat)]] {
            var write_page_field = Array.init<[(Nat, Nat)]>(chunk_number, []);
            var write_page_size : Nat = 0; 
            var ptr : Nat = read_page_field[0].0;
            var read_page_size : Nat = read_page_field[0].1;
            var read_page_index : Nat = 0;

            label l for (write_page_index in Iter.range(0, chunk_number - 1)) {
                var res : [var (Nat, Nat)] = [var];
                write_page_size := _getWritePageSize(write_page_index, chunk_number, total_size);
                while (write_page_size > 0 and read_page_index < read_page_field.size()) {
                    if (read_page_size > write_page_size) {
                        res := _appendArray(res, [var (ptr, write_page_size)]);
                        ptr += write_page_size;
                        read_page_size -= write_page_size;
                        write_page_size := 0;
                    } else {
                        res := _appendArray(res, [var (ptr, read_page_size)]);
                        ptr += read_page_size;
                        write_page_size -= read_page_size;   
                        read_page_index += 1;  

                        if (read_page_index < read_page_field.size()) {
                            ptr := read_page_field[read_page_index].0;
                            read_page_size := read_page_field[read_page_index].1;
                        };
                    }
                };
                write_page_field[write_page_index] := Array.freeze<(Nat, Nat)>(res);
            };
            Array.freeze<[(Nat, Nat)]>(write_page_field)
        };

        private func _preUpgrade() : Text {
            var key_index : Nat = 0;
            key_name_entries := Array.init<(Text, Text)>(key_name_map.size(), ("", ""));
            for (key_name_entry in key_name_map.entries()) {
                key_name_entries[key_index] := (key_name_entry.0, key_name_entry.1);
                key_index += 1;
            };

            var asset_index = 0;
            let asset : Asset = {
                file_key  = ""; 
                file_name = "";
                file_extension = "";
                total_size = 0; 
                page_field = [];
            };
            asset_entries := Array.init<(Text, Asset)>(asset_map.size(), ("", asset));
            for (asset_entry in asset_map.entries()) {
                asset_entries[asset_index] := (asset_entry.0, {
                    file_key  = asset_entry.1.file_key;
                    file_name = asset_entry.1.file_name;
                    file_extension = asset_entry.1.file_extension;
                    total_size = asset_entry.1.total_size;
                    page_field = asset_entry.1.page_field;
                });
                asset_index += 1;
            };
            return ("Pre Upgrade Successfully.")
        };
    }
}
