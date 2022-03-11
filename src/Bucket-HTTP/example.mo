import Result "mo:base/Result";
import BucketHTTP "BucketHTTP";
import Types "Types";

actor test {

    type PUT = Types.PUT;
    type AssetExt = Types.AssetExt;
    type DataErr = Types.DataErr;
    type GET = Types.GET;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    type CallbackToken = Types.CallbackToken;
    type StreamingCallbackHttpResponse = Types.StreamingCallbackHttpResponse;
    type StreamingCallback  = query (CallbackToken) -> async (StreamingCallbackHttpResponse);

    let bucket = BucketHTTP.BucketHTTP();
    
    public shared func put(p : PUT, caller : Principal) : async Result.Result<AssetExt, DataErr> {
        bucket.put(p, caller)     
    };

    public query func get(g : GET) : async Result.Result<Blob, DataErr> {
        bucket.get(g)
    };
    
    public shared func build_http(newSCB: StreamingCallback) : async () {
        bucket.build_http(newSCB)
    };

    public query func http_request(request: HttpRequest) : async HttpResponse {
        bucket.http_request(request)
    };
};