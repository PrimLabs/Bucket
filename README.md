# Bucket

The Project is a **storage standard** applied to canisters.

Its goal is to become a general data storage standard on [Internet Computer](https://dfinity.org/) (IC). By using this standard, just **one line of import code**, developers can easily use data storage functions such as put, get when writing canister smart contracts on IC without repeating develop this aspect.

In order to be compatible with the existing development ecology, we develop two version standard:

- Bucket
- Bucket-HTTP

You can use this just like using the TireMap.

##  Bucket

- First, you need to import bucket in your project 

​       ``import Bucket "Bucket";``

- Second, you need to declare a Bucket, e.g.：

​       ``let bucket = Bucket.Bucket(); ``

You can then put and get large files.

- put files in canister：

  调用函数： 

  ``public func put(p : PUT, caller : Principal) : Result.Result<AssetExt, DataErr>``

  example：``bucket.put(p, caller)``;

- get files from canister:

  调用函数：

  `` public func get(g : GET) : Result.Result<Blob, DataErr>``

  example：``bucket.get(g);``

- For the explanation of Types, please refer to the code comments

##  Bucket-HTTP

The difference between Bucket-HTTP and Bucket is that Bucket-HTTP has built-in **http_request**, so people can query files through **canisterID.raw.ic0.app/fk/file_key**

example:``bs5jn-2aaaa-aaaai-qhtaq-cai.raw.ic0.app/fk/8B091EE0CB685ABD376F7645A6A57E9E118671DF003444C1C13B37E2FCAFCEA7``

Due to the problem of IC mainnet, HTTP-StreamingCallback cannot work at present, so only files less than or equal to **3M** can be accessed through http.

We will fix this deficiency as soon as possible.

## Disclaimer

YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT USE OF THIS SOFTWARE IS AT YOUR SOLE RISK. AUTHORS OF THIS SOFTWARE SHALL NOT BE LIABLE FOR DAMAGES OF ANY TYPE, WHETHER DIRECT OR INDIRECT.

## Contributing

We'd like to collaborate with the community to provide better data storage standard implementation for the developers on the IC, if you have some ideas you'd like to discuss, submit an issue, if you want to improve the code or you made a different implementation, make a pull request!