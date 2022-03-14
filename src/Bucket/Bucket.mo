import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import SM "mo:base/ExperimentalStableMemory";

module {

    public class Bucket<K, V>() {
        
        type Error = {
            #INSUFFICIENT_MEMORY;
            #BlobSizeError;
            #INVALID_KEY;
        };
        private let THRESHOLD               = 6442450944;
        private let MAX_UPDATE_SIZE         = 1992295;
        private let PAGE_SIZE               = 65536;
        private let MAX_PAGE_NUMBER : Nat32 = 98304;
        private let MAX_QUERY_SIZE          = 3144728;
        private var offset                  = 0;
        var assets = TrieMap.TrieMap<Blob, [(Nat, Nat)]>(Blob.equal, Blob.hash);
        var asset_entries: [var (Blob, [(Nat, Nat)])] = [var];

        public func putBlob(key: Blob,data: Blob): Result.Result<(), Error> {
            switch(_readPageField(data.size())) {
                case(#ok(pagefield)) {
                    assets.put(key, pagefield);
                    #ok(_storageData(pagefield, data));
                };
                case(#err(err)) {#err(err)};
            };   
        };
        
        public func put(key: Blob, v: V, serialization: V -> Blob): Result.Result<(), Error> {
            let data = serialization(v);
            switch(_readPageField(data.size())) {
                case(#ok(pagefield)) {
                    assets.put(key, pagefield);
                    #ok(_storageData(pagefield, data));
                };
                case(#err(err)) {#err(err)};
            };           
        };        

        public func getBlob(key: Blob): Result.Result<Blob, Error> {
            switch(assets.get(key)) {
                case(null) { return #err(#INVALID_KEY) };
                case(?pagefield) {
                    #ok(_getStableMemory(pagefield[0]))
                };
            };
        };

        public func get(key: Blob, deserialize: Blob -> V): Result.Result<V, Error> {
            switch(assets.get(key)) {
                case(null) { return #err(#INVALID_KEY) };
                case(?pagefield) {
                    let data = _getStableMemory(pagefield[0]);
                    #ok(deserialize(data))
                };
            };
        };

        public func preupgrdae(): () {
            var asset_index = 0;
            let asset = (Text.encodeUtf8(""), []);
            asset_entries := Array.init<(Blob, [(Nat, Nat)])>(assets.size(), asset);
            for (asset_entry in assets.entries()) {
                asset_entries[asset_index] := (asset_entry.0, asset_entry.1); 
                asset_index += 1;
            };
        };

        public func postupgrade(): () {
            asset_entries := [var ];
        };


        private func _getStableMemory(field : (Nat, Nat)) : Blob {
            SM.loadBlob(Nat32.fromNat(field.0), field.1)
        };

        // check total_size
        private func _inspectSize(total_size : Nat) : Result.Result<Nat, Error> {
            if (total_size == 0) { return #err(#BlobSizeError) };
            if (total_size <= _getAvailableStableMemory()) { #ok(total_size) } else { #err(#INSUFFICIENT_MEMORY) };
        };
        
        // file preallocation
        private func _readPageField(total_size : Nat) : Result.Result<[(Nat, Nat)], Error> {
            // 检查可用空间是否放得下文件
            // Check if the free space can fit the file
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

        // upload时根据分配好的write_page以vals的形式写入数据
        // When uploading, write data in the form of vals according to the assigned write_page
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

        private func _getAvailableStableMemory() : Nat{
            THRESHOLD - offset
        };

        // grow SM memory pages of size "size"
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

        // Get the number of SM memory pages that need to grow
        private func _getStableMemoryPageNumber(size : Nat) : Nat32 {
            Nat32.fromNat(size / PAGE_SIZE + 1)
        };

    }; 
};