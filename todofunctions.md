Class Bucket()

### Type

  struct Error = {
    #INSUFFICIENT_MEMORY;
    #INVALID_KEY;
  }


### Map
  non-stable : var assets : TrieMap<Blob, [(Nat, Nat)]> \
  stable var assets_entries : [(Blob, [(Nat, Nat)])]

### Put
  putBlob : (Blob, Blob) -> Result<(), Error> \
  put<V> : (Blob, V, func : V -> Blob) // func is used for transforming the value to Blob for being stored into stable memory 

### Get
  getBlob : Blob -> Result<Blob, Error> \ 
  get<V> : (Blob, func : Blob -> V) -> Result<V, Error>

### Upgrade
  public func preupgrade : transform the assets into assets_entries \
  public func postupgrade : assets_entries := []
