import Bucket "Bucket";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";

actor example{

    type Error = Bucket.Error;
    type S = {
        text : Text;
        bool : Bool
    };
    stable var bucket_entries : [(Text, [(Nat64, Nat)])] = [];
    let bucket = Bucket.Bucket(true); // true : upgradable, false : unupgradable

    public query func getBlob(key : Text) : async Result.Result<[Blob], Error>{
        switch(bucket.get(key)){
            case(#err(e)){ #err(e) };
            case(#ok(blob)){
                #ok(blob)
            }
        }
    };

    public query func get(key : Text) : async Result.Result<[S], Error>{
        switch(bucket.get(key)){
            case(#err(info)){ #err(info) };
            case(#ok(data)){ #ok(deserialize(data)) };
        };
    };

    public func put() : async Result.Result<(), Error>{
        let key = "key";
        let value_1 : S = {
            text = "this is the first slice of value";
            bool = true
        };
        let value_2 : S = {
            text = "this is the second slice of value";
            bool = false
        };
        switch(bucket.put(key, serialize(value_1))){
            case(#err(e)){ return #err(e) };
            case(_){};
        };
        // you can storage the two different value using the same key
        switch(bucket.put(key, serialize(value_2))){
            case(#err(e)){ return #err(e) };
            case(_){};
        };
        #ok(())
    };

    public func putBlob() : async Result.Result<(), Error>{
        let key = "key";
        let value = Text.encodeUtf8("this is the value");
        switch(bucket.put(key, value)){
            case(#err(e)){ return #err(e) };
            case(_){};
        };
        #ok(())
    };

    system func preupgrade(){
        bucket_entries := bucket.preupgrade();
    };

    system func postupgrade(){
        bucket.postupgrade(bucket_entries);
        bucket_entries := [];
    };

    // you should encode the segment of the struct into nat8
    // then you should merge them and transform the [Nat8] to Blob
    private func serialize(s : S) : Blob{
        let bool_nat8 = if(s.bool){
            1 : Nat8
        }else{ 0 : Nat8 };
        let text_blob = Text.encodeUtf8(s.text);
        let text_nat8 = Blob.toArray(text_blob);
        let serialize_data = Array.append<Nat8>(text_nat8, [bool_nat8]);
        Blob.fromArray(serialize_data)
    };

    private func deserialize(data : [Blob]) : [S] {
        let res = Array.init<S>(data.size(), {
            text = "";
            bool = true;
        });
        var res_index = 0;
        for(d in data.vals()){
            let raw = Blob.toArray(d);
            let bool = if(raw[Nat.sub(raw.size(), 1)] == 1){ true }else{ false };
            let text = Array.init<Nat8>(Nat.sub(data.size(), 2), 0:Nat8);// the last byte is used to store the "bool"
            var index = 0;
            label l for(d in raw.vals()){
                text[index] := d;
                index += 1;
                if(index == text.size()){ break l };
            };
            let t =
                switch(Text.decodeUtf8(Blob.fromArray(Array.freeze<Nat8>(text)))){
                    case null { "" };
                    case(?te){ te };
                };
            res[res_index] :=
                {
                    text = t;
                    bool = bool
                };
            res_index += 1;
        };
        Array.freeze(res)
    };

}
