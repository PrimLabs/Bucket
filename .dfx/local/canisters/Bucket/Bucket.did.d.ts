import type { Principal } from '@dfinity/principal';
export interface AssetExt {
  'file_extension' : string,
  'upload_status' : boolean,
  'bucket_id' : Principal,
  'file_name' : string,
  'file_key' : string,
  'total_size' : bigint,
  'need_query_times' : bigint,
}
export interface CallbackToken {
  'key' : string,
  'max_index' : bigint,
  'index' : bigint,
}
export interface CallbackToken__1 {
  'key' : string,
  'max_index' : bigint,
  'index' : bigint,
}
export interface Chunk { 'data' : Array<number>, 'digest' : Array<number> }
export type DataErr = { 'FileKeyErr' : null } |
  { 'BlobSizeError' : null } |
  { 'FlagErr' : null } |
  { 'MemoryInsufficient' : null };
export interface GET { 'flag' : bigint, 'file_key' : string }
export type HeaderField = [string, string];
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
}
export interface HttpResponse {
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export interface PUT {
  'file_extension' : string,
  'chunk_number' : bigint,
  'chunk' : Chunk,
  'file_name' : string,
  'file_key' : string,
  'total_size' : bigint,
  'chunk_order' : bigint,
}
export type Result = { 'ok' : AssetExt } |
  { 'err' : DataErr };
export type Result_1 = { 'ok' : Array<number> } |
  { 'err' : DataErr };
export type StreamingCallback = (arg_0: CallbackToken__1) => Promise<
    StreamingCallbackHttpResponse__1
  >;
export interface StreamingCallbackHttpResponse {
  'token' : [] | [CallbackToken],
  'body' : Array<number>,
}
export interface StreamingCallbackHttpResponse__1 {
  'token' : [] | [CallbackToken],
  'body' : Array<number>,
}
export type StreamingStrategy = {
    'Callback' : { 'token' : CallbackToken, 'callback' : [Principal, string] }
  };
export interface _SERVICE {
  'build_http' : (arg_0: [Principal, string]) => Promise<undefined>,
  'get' : (arg_0: GET) => Promise<Result_1>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'put' : (arg_0: PUT, arg_1: Principal) => Promise<Result>,
}
