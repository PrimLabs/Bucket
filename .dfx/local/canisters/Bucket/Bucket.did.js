export const idlFactory = ({ IDL }) => {
  const CallbackToken__1 = IDL.Record({
    'key' : IDL.Text,
    'max_index' : IDL.Nat,
    'index' : IDL.Nat,
  });
  const CallbackToken = IDL.Record({
    'key' : IDL.Text,
    'max_index' : IDL.Nat,
    'index' : IDL.Nat,
  });
  const StreamingCallbackHttpResponse__1 = IDL.Record({
    'token' : IDL.Opt(CallbackToken),
    'body' : IDL.Vec(IDL.Nat8),
  });
  const StreamingCallback = IDL.Func(
      [CallbackToken__1],
      [StreamingCallbackHttpResponse__1],
      ['query'],
    );
  const GET = IDL.Record({ 'flag' : IDL.Nat, 'file_key' : IDL.Text });
  const DataErr = IDL.Variant({
    'FileKeyErr' : IDL.Null,
    'BlobSizeError' : IDL.Null,
    'FlagErr' : IDL.Null,
    'MemoryInsufficient' : IDL.Null,
  });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Vec(IDL.Nat8), 'err' : DataErr });
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const StreamingCallbackHttpResponse = IDL.Record({
    'token' : IDL.Opt(CallbackToken),
    'body' : IDL.Vec(IDL.Nat8),
  });
  const StreamingStrategy = IDL.Variant({
    'Callback' : IDL.Record({
      'token' : CallbackToken,
      'callback' : IDL.Func(
          [CallbackToken],
          [StreamingCallbackHttpResponse],
          ['query'],
        ),
    }),
  });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'streaming_strategy' : IDL.Opt(StreamingStrategy),
    'status_code' : IDL.Nat16,
  });
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
    'build_http' : IDL.Func([StreamingCallback], [], []),
    'get' : IDL.Func([GET], [Result_1], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'put' : IDL.Func([PUT, IDL.Principal], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
