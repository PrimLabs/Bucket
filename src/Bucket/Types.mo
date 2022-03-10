import TrieMap "mo:base/TrieMap";

module{
    
    public type Chunk = {
        digest : [Nat8];
        data : Blob;
    };

    public type Asset = {
        file_key :  Text; 
        file_name : Text;
        file_extension : Text;
        total_size : Nat; 
        page_field : [(Nat, Nat)]; 
    };

    public type AssetBuffer = {
        chunk_number : Nat;
        total_size : Nat;
        digest : [var Nat8]; 
        read_page_field : [(Nat, Nat)];
        write_page_field : [[(Nat, Nat)]];
        wrote_page : [var Bool];
        var received : Nat; 
    };

    public type AssetExt = {
        bucket_id : Principal;
        file_key : Text;
        file_name : Text;
        file_extension : Text;
        total_size : Nat;
        upload_status : Bool;
        need_query_times : Nat; 
    };

    public type PUT = {
        file_key : Text;
        file_name : Text;
        file_extension : Text;
        chunk : Chunk;
        chunk_number : Nat;
        chunk_order : Nat;
        total_size : Nat;
    };

    public type GET = {
        file_key : Text;
        flag : Nat;
    };

    public type DataErr = {
        #MemoryInsufficient;
        #BlobSizeError;
        #FileKeyErr;
        #FlagErr;
    };

// ----------HTTP-------------------------

    public type HeaderField = (Text, Text);

    public type CallbackToken = {
        index: Nat;
        max_index: Nat;
        key: Text;
    };

    public type StreamingCallbackHttpResponse  = {
        body: Blob;
        token: ?CallbackToken;
    };

    public type StreamingStrategy  = {
        #Callback: {
            callback: query (CallbackToken) -> async (StreamingCallbackHttpResponse);
            token: CallbackToken;
        }
    };

    public type HttpRequest = {
        method: Text;
        url: Text;
        headers: [HeaderField];
        body: Blob;
    };

    public type HttpResponse = {
        status_code: Nat16;
        headers: [HeaderField];
        body: Blob;
        streaming_strategy: ?StreamingStrategy ;
    };
};