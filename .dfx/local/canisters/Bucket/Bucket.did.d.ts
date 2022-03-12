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
export interface Chunk { 'data' : Array<number>, 'digest' : Array<number> }
export type DataErr = { 'FileKeyErr' : null } |
  { 'BlobSizeError' : null } |
  { 'FlagErr' : null } |
  { 'MemoryInsufficient' : null };
export interface GET { 'flag' : bigint, 'file_key' : string }
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
export interface _SERVICE {
  'get' : (arg_0: GET) => Promise<Result_1>,
  'put' : (arg_0: PUT, arg_1: Principal) => Promise<Result>,
}
