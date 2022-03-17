import BucketHttp "Bucket-HTTP";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import SM "mo:base/ExperimentalStableMemory";

actor example{

    type HttpRequest = BucketHttp.HttpRequest; 
    type HttpResponse = BucketHttp.HttpResponse;

    type Error = BucketHttp.Error;
    stable var entries : [(Text, [(Nat64, Nat)])] = [];
    let bucket = BucketHttp.BucketHttp(true); // true : upgradable, false : unupgradable
    
    //host/static/<photo_id>
    private func decodeurl(url: Text): Text {
        let path = Iter.toArray(Text.tokens(url, #text("/")));
        if(path.size() == 2 and path[0] == "static") {
            return path[1];
        };
        return "Wrong key";
    };

    public func build_http(): async () {
        bucket.build_http(decodeurl);
    };

    public query func http_request(request: HttpRequest): async HttpResponse {
        bucket.http_request(request)
    };

    public query func getBlob(key: Text) : async Result.Result<[Blob], Error>{
        switch(bucket.get(key)){
            case(#err(e)){ #err(e) };
            case(#ok(blob)){
                #ok(blob)
            }
        }
    };

    public shared func putImg(key: Text,value: Blob) : async Result.Result<(), Error>{
        switch(bucket.put(key, value)){
            case(#err(e)){ return #err(e) };
            case(_){};
        };
        #ok(())
    };

    public shared func putBlob() : async Result.Result<(), Error>{
        let key = "key";
        let value = Text.encodeUtf8("this is the value");
        switch(bucket.put(key, value)){
            case(#err(e)){ return #err(e) };
            case(_){};
        };
        #ok(())
    };

    system func preupgrade(){
        entries := bucket.preupgrade();
    };

    system func postupgrade(){
        bucket.postupgrade(entries);
        entries := [];
    };

}
