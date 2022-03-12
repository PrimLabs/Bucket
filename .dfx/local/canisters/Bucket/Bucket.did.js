export const idlFactory = ({ IDL }) => {
  const GET = IDL.Record({ 'flag' : IDL.Nat, 'file_key' : IDL.Text });
  const DataErr = IDL.Variant({
    'FileKeyErr' : IDL.Null,
    'BlobSizeError' : IDL.Null,
    'FlagErr' : IDL.Null,
    'MemoryInsufficient' : IDL.Null,
  });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Vec(IDL.Nat8), 'err' : DataErr });
  const Chunk = IDL.Record({
    'data' : IDL.Vec(IDL.Nat8),
    'digest' : IDL.Vec(IDL.Nat8),
  });
  const PUT = IDL.Record({
    'file_extension' : IDL.Text,
    'chunk_number' : IDL.Nat,
    'chunk' : Chunk,
    'file_name' : IDL.Text,
    'file_key' : IDL.Text,
    'total_size' : IDL.Nat,
    'chunk_order' : IDL.Nat,
  });
  const AssetExt = IDL.Record({
    'file_extension' : IDL.Text,
    'upload_status' : IDL.Bool,
    'bucket_id' : IDL.Principal,
    'file_name' : IDL.Text,
    'file_key' : IDL.Text,
    'total_size' : IDL.Nat,
    'need_query_times' : IDL.Nat,
  });
  const Result = IDL.Variant({ 'ok' : AssetExt, 'err' : DataErr });
  return IDL.Service({
    'get' : IDL.Func([GET], [Result_1], ['query']),
    'put' : IDL.Func([PUT, IDL.Principal], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
