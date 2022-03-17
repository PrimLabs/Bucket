# Bucket

The library is a **storage library** for canisters to manage Stable Memory. 

As far as we know, canisters that storage data into stable memory have many advantages, such as :
- upgradable (when rts memory goes large)
- larger storage space : Stable Memory can be allocated to 8 GB as present
- no gc cost

Therefore, In order to be compatible with the existing development ecology, we develop two versions :

- [Bucket](#Bucket)
- [Bucket-HTTP](#Bucket-HTTP)

You can use this as simple as using the TireMap.

<span id="Bucket"></span>

##  Bucket

- First, you need to import Bucket in your project 

   ```motoko
   import Bucket "Bucket";
   ```

- Second, you need to declare a Bucket

   **upgrade** ：This means that you can upgrade your canister without discarding files stored in the stablememory
   
   ```motoko
   let bucket = Bucket.Bucket(true); // true : upgradable, false : unupgradable
   ```
   
   **unupgradable** : This means that if you upgrade your canister, you will discard files stored in the stablememory
   
   ```motoko
   let bucket = Bucket.Bucket(false); // true : upgradable, false : unupgradable
   ```

###  API

- **put** ：put the value into stablememory,use key to index

  ```motoko
  public func put(key: Text, value : Blob): Result.Result<(), Error>
  ```

- **get** : use the key to get the value

  ```motoko
  public func get(key: Text): Result.Result<[Blob], Error>
  ```

- **preupgrade** : return entries

  ```motoko
  public func preupgrade(): [(Text, [(Nat64, Nat)])]
  ```

- **postupgrade**

  ```motoko
  public func postupgrade(entries : [(Text, [(Nat64, Nat)])]): ()
  ```

**[more details please read the demo](https://github.com/PrimLabs/Bucket/blob/main/src/Bucket/example.mo)**

<span id="Bucket-HTTP"></span>

##  Bucket-HTTP

The difference between Bucket-HTTP and Bucket is that Bucket-HTTP has built-in **http_request**, so people can query files through example : **canisterID.raw.ic0.app/static/key**

example

```
https://2fli5-jyaaa-aaaao-aabea-cai.raw.ic0.app/static/0
```

Due to the problem of IC mainnet, HTTP-StreamingCallback cannot work at present, so only files less than or equal to **2M** can be accessed through http.

**We will fix this deficiency as soon as possible.**

- First, you need to import Bucket-HTTP in your project 

   ```motoko
   import BucketHttp "Bucket-HTTP";
   ```

- Second, you need to declare a Bucket-HTTP

   **upgrade** ：This means that you can upgrade your canister without discarding files stored in the stablememory
   
   ```motoko
   let bucket = BucketHttp.BucketHttp(true); // true : upgradable, false : unupgradable
   ```
   
   **unupgradable** : This means that if you upgrade your canister, you will discard files stored in the stablememory
   
   ```motoko
   let bucket = BucketHttp.BucketHttp(false);// true : upgradable, false : unupgradable
   ```

###  API

- **put** ：put the value into stablememory,use key to index

  ```motoko
  public func put(key: Text, value : Blob): Result.Result<(), Error>
  ```

- **get** : use the key to get the value

  ```motoko
  public func get(key: Text): Result.Result<[Blob], Error>
  ```

- **build_http** : Pass in the function that parses the key in the url,the key is used to get the value
- ATTENTION : YOU MUST SET YOUR DECODE FUNCITON OR REWRITE IT AND CALL THE BUILD FUNCTION TO ENABLE IT WHEN YOU NEED TO USE THE HTTP INTERFACE.

  ```motoko
  public func build_http(fn_: DecodeUrl): ()
  ```

  ```motoko
  public type DecodeUrl = (Text) -> (Text);
  ```

- **http_request**

  ```motoko
  public func http_request(request: HttpRequest): HttpResponse
  ```

- **preupgrade** : return entries

  ```motoko
  public func preupgrade(): [(Text, [(Nat64, Nat)])]
  ```

- **postupgrade**

  ```motoko
  public func postupgrade(entries : [(Text, [(Nat64, Nat)])]): ()
  ```

**[more details please read the demo](https://github.com/PrimLabs/Bucket/blob/main/src/Bucket-HTTP/example.mo)**

## dfx.json
you should point out how much stable memory pages you want to use in dfx.json
```
"build" :{
   "args": "--max-stable-pages=131072" // the max size is 131072 [131072 = 8G / 64KB(each page size)]
}
```


## Disclaimer

YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT USE OF THIS SOFTWARE IS AT YOUR SOLE RISK. AUTHORS OF THIS SOFTWARE SHALL NOT BE LIABLE FOR DAMAGES OF ANY TYPE, WHETHER DIRECT OR INDIRECT.

## Contributing

<span id="hh"></span>

We'd like to collaborate with the community to provide better data storage standard implementation for the developers on the IC, if you have some ideas you'd like to discuss, submit an issue, if you want to improve the code or you made a different implementation, make a pull request!
