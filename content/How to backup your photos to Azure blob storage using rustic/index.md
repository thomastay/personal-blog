---
title: How to backup your photos to Azure blob storage using rustic
date: 2024-11-09T00:31:00-07:00
draft: true
---
## Basic summary of my backup strategy
- I backup my files to Azure blob storage
- I have 3 backups following the [3-2-1 backup strategy](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/). 
- For my primary storage location I have a Onedrive backup which backs up photos from my phone. I consider this the primary, and my files are kept here
- For my secondary backup, I have a 2TB Seagate Backup Plus external HDD that I use rclone to mirror my Onedrive to.
- But until now, I didn't have a third backup option. I wanted something cheap.
### Why Azure blob storage?
After evaluating various options, I decided to go with Azure blob storage, on the Archive tier. For anyone hoping to replicate this, it's important to know that Azure blob storage archive tier is meant as Archival storage, meaning it should be option #3 in a [3-2-1 backup strategy](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/). It's not meant as a backup, which would be the role of the 2TB HDD in my case.

I have 180GB of data to store. On Azure archive storage, these are the costs I will pay:
- $0.30 to write the data to storage, a one time cost that's basically negligible
- $0.18 / month to store it, which amounts to $2.16 per year.
- $3.60 for retrieval fees if I ever decide to retrieve it. 
- $7.00 to move it from Azure to my hard drive (aka egress). The first 100GB of egress is free, so it's (80 * 0.087 = $7)

Assuming I restore at most once in a 10 year period, that's a combined cost of $33 for 10 years.
For comparison, storing with Backblaze B2 would cost $129 over the same period. That's a **75%** discount, which is pretty significant.

AWS has a similar program called AWS S3 Glacier. Both AWS and Azure are basically the same price wise, so I would recommend you go with whichever one is more familiar to you. [Miroslav Prasil has an excellent writeup on the economics and technical side of storage in AWS S3 Glacier](https://kmh.prasil.info/posts/rustic-cold-storage-glacier-economics/)

*Full disclosure - I work for Microsoft, but not for Azure, and I don't get paid to recommend Azure*
## What is Rustic?
[Rustic](https://rustic.cli.rs/docs/getting_started.html) is an reimplementation of the popular backup software [Restic](https://restic.net/). For those unfamiliar, Restic is a backup software tool that encrypts, deduplicates, and compresses your files into blobs suitable for uploading to the cloud.

Rustic adds on an additional feature for cold storage, meaning it's designed for use in AWS S3 Glacier and Azure Archive storage. This makes it ideal for us here.

It's also written in Rust, if that appeals to you. It does to me.
#### Why not just Restic?
Restic's backup strategy is good, but isn't designed for cold storage. Instead of diving into the details of blobs and packfiles, let's run a simple scenario to show where Restic is lacking, and where Rustic shines.

Suppose you backup your photos today to Azure. Next month, when doing your monthly backup, you'll want to only backup photos that have changed between last month and this one. In order to do that, you'll have to check what's there in Azure storage to see what's changed.

The problem is that your data is all stored in cold storage, so you have to restore it to hot storage, which costs \$\$ and takes hours if not days. Then you can upload the new or changed files, and then move the data back into cold storage. This all takes time and additional money, which is ultimately inefficient.

What if we just stored an additional **index** of the files that are archived, and keep the index in Azure's hot storage tier? Then when we do our next backup, we check what's changed against the index, and only upload any new or changed files?

Well, that's what Rustic does. It allows you to define an additional **hot storage** location, so that checking for what files have changed is something that can be done entirely from the data in the hot storage. Only when you want to upload actual data, do you interact with the cold storage. 

Rustic also ensures that data in the cold storage is never overwritten, since that would cost money for retrieval. Instead, it just writes more blobs to cold storage, and if you ever retrieve it in the future, it does the work of figuring out what the latest version is.

# How do you do it?




```
[repository]
repo-hot = "opendal:azblob"
repository = "opendal:azblob"
throttle = "5MiB,200MiB"

[repository.options]
container = "cold-onedrive-2"
root = "/"
account_name = "accountName"
account_key = <secret key>
endpoint = "https://{accountName}.blob.core.windows.net"
throttle = "5MiB,200MiB"

[repository.options-hot]
container = "hot-onedrive-2"
root = "/"
account_name = "accountName"
account_key = <secret key>
endpoint = "https://{accountName}.blob.core.windows.net"
throttle = "5MiB,200MiB"

[INFO] using config C:\Users\...\AppData\Roaming\rustic\config\azure.toml
[WARN] service=azblob name=cold-onedrive-2 path=config: stat failed NotFound (persistent) at stat, context: { uri: https://{accountName}.blob.core.windows.net/cold-onedrive-2/config, response: Parts { status: 404, version: HTTP/1.1, headers: {"transfer-encoding": "chunked", "server": "Windows-Azure-Blob/1.0 Microsoft-HTTPAPI/2.0", "x-ms-request-id": "28c631e8-b01e-0012-6960-23691b000000", "x-ms-version": "2022-11-02", "x-ms-error-code": "BlobNotFound", "date": "Mon, 21 Oct 2024 02:24:10 GMT"} }, service: azblob, path: config } => AzblobError { code: "BlobNotFound", message: "" }
[WARN] service=azblob name=cold-onedrive-2 path=config: stat failed NotFound (persistent) at stat, context: { uri: https://{accountName}.blob.core.windows.net/cold-onedrive-2/config, response: Parts { status: 404, version: HTTP/1.1, headers: {"transfer-encoding": "chunked", "server": "Windows-Azure-Blob/1.0 Microsoft-HTTPAPI/2.0", "x-ms-request-id": "28c6322a-b01e-0012-2860-23691b000000", "x-ms-version": "2022-11-02", "x-ms-error-code": "BlobNotFound", "date": "Mon, 21 Oct 2024 02:24:10 GMT"} }, service: azblob, path: config } => AzblobError { code: "BlobNotFound", message: "" }
[INFO] key 35a2ccd4 successfully added.
[INFO] repository 0a5d05d6 successfully created.
[09:15:16] backing up...                  ████████████████████████████████████████ 170.88 GiB/170.88 GiB 5.25 MiB/s

Files:       66878 new, 0 changed, 0 unchanged
Dirs:        952 new, 0 changed, 0 unchanged
snapshot a410a67f successfully saved.

$ rustic repoinfo

repository files

| File type | Count | Total Size |
|-----------|-------|------------|
| Key       |     1 |      363 B |
| Snapshot  |     1 |      601 B |
| Index     |   110 |    8.4 MiB |
| Pack      |  4102 |  163.5 GiB |
| Total     |  4214 |  163.5 GiB |

hot repository files

| File type | Count | Total Size |
|-----------|-------|------------|
| Key       |     1 |      363 B |
| Snapshot  |     1 |      601 B |
| Index     |   110 |    8.4 MiB |
| Pack      |    33 |    7.9 MiB |
| Total     |   145 |   16.3 MiB |


| Blob type |  Count | Total Size | Total Size in Packs |
|-----------|--------|------------|---------------------|
| Tree      |    900 |   23.9 MiB |             7.8 MiB |
| Data      | 169570 |  165.3 GiB |           163.5 GiB |
| Total     | 170470 |  165.3 GiB |           163.5 GiB |

| Blob type  | Pack Count | Minimum Size | Maximum Size |
|------------|------------|--------------|--------------|
| Tree packs |         33 |        299 B |      2.7 MiB |
| Data packs |       4069 |     10.0 MiB |     49.2 MiB |
```