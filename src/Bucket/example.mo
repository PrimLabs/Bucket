import Result "mo:base/Result";
import Bucket "Bucket";
import Types "Types";

actor test {

    type PUT = Types.PUT;
    type AssetExt = Types.AssetExt;
    type DataErr = Types.DataErr;
    type GET = Types.GET;

    let bucket = Bucket.Bucket();
    
    public shared func put(p : PUT, caller : Principal) : async Result.Result<AssetExt, DataErr> {
        bucket.put(p, caller)     
    };

    public query func get(g : GET) : async Result.Result<Blob, DataErr> {
        bucket.get(g)
    };
    
};