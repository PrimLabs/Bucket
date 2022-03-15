use anyhow::anyhow;
use candid::{CandidType, Decode, Encode};
use ic_agent::agent::http_transport::ReqwestHttpReplicaV2Transport;
use ic_agent::Agent;
use ic_types::Principal;
use serde::Deserialize;
use std::fs;
use std::fs::OpenOptions;
use std::io::Write;
use std::sync::Arc;
use tokio::main;

static UPDATE_SIZE: usize = 2096128;

#[derive(Debug, Deserialize, CandidType)]
enum E {
    INSUFFICIENT_MEMORY,
    BlobSizeError,
    INVALID_KEY,
}

#[derive(Debug, Deserialize, CandidType)]
enum R {
    err(E),
    ok,
}

#[tokio::main]
async fn main() {
    let (file_size, data_slice) = get_file_from_source("img.png");
    println!("pre upload file size : {}", file_size);
    let url = "https://ic0.app";
    let transport = ReqwestHttpReplicaV2Transport::create(url).unwrap();
    let agent = Arc::new(Agent::builder().with_transport(transport).build().unwrap());
    let _ = agent.fetch_root_key().await;
    let canister_id = Principal::from_text("d5cux-byaaa-aaaag-aabhq-cai").unwrap();
    let key = "key".as_bytes().to_vec();
    let r = upload_file_serially(agent.clone(), &canister_id, &key, &data_slice).await;
    println!("{:?}", r);
    let mut file = OpenOptions::new()
        .read(true)
        .write(true)
        .append(true)
        .create(true)
        .open("to_img")
        .unwrap();
    for i in 0..data_slice.len() {
        file.write_all(
            &get(agent.clone(), &canister_id, &key, &(i as u128))
                .await
                .unwrap(),
        )
        .expect("write into file failed")
    }
}

// 从文件路劲访问文件，切片并且返回 [每一片] 数组
fn get_file_from_source(path: &str) -> (usize, Vec<Vec<u8>>) {
    let context = fs::read(path).expect("read file failed");
    let size = context.len();
    println!("file size : {}", context.len());
    let slice_size = if context.len() % UPDATE_SIZE == 0 {
        context.len() / UPDATE_SIZE
    } else {
        context.len() / UPDATE_SIZE + 1
    };
    let mut res = Vec::new();
    for index in 0..slice_size {
        if index == slice_size - 1 {
            res.push(context[index * UPDATE_SIZE..context.len()].to_owned())
        } else {
            res.push(context[index * UPDATE_SIZE..(index + 1) * UPDATE_SIZE].to_owned())
        }
    }
    println!("file chunk number : {}", res.len());
    (size, res)
}

async fn upload_file_serially(
    agent: Arc<Agent>,
    canister_id: &Principal,
    key: &Vec<u8>,
    data: &Vec<Vec<u8>>,
) -> anyhow::Result<String> {
    for put in data {
        let waiter = garcon::Delay::builder()
            .throttle(std::time::Duration::from_millis(500))
            .timeout(std::time::Duration::from_secs(60 * 5))
            .build();
        let response = agent
            .update(canister_id, "putBlob")
            .with_arg(Encode!(key, put).expect("encode piece failed"))
            .call_and_wait(waiter)
            .await?;
        println!(
            "response {:?}: ",
            Decode!(&response, R).expect("decode response failed")
        )
    }
    Ok(String::from("upload file serially"))
}
#[derive(Debug, Deserialize, CandidType)]
enum GetResult {
    ok(Vec<u8>),
    err(E),
}

async fn get(
    agent: Arc<Agent>,
    canister_id: &Principal,
    key: &Vec<u8>,
    index: &u128,
) -> anyhow::Result<Vec<u8>> {
    let res = agent
        .query(canister_id, "getBlob")
        .with_arg(Encode!(key, index).unwrap())
        .call()
        .await
        .unwrap();
    let res = Decode!(&res, GetResult).unwrap();
    println!("{}", "get successfully".to_string());
    if let GetResult::ok(blob) = res {
        Ok(blob)
    } else {
        Err(anyhow!("get file data failed"))
    }
}
