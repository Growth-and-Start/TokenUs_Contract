import React, { useState } from "react";
import { createPublicClient, http } from "viem";
import { polygon, polygonAmoy } from "viem/chains";
import {
  nft,
  approvals,
  market,
  utils,
} from "../../../sdk/src/index";
import { getTokensOfWork } from "../../../sdk/src/nft";
import{createClient} from "../../../sdk/src/client";

const RPC_URL = "https://rpc-amoy.polygon.technology";
const CHAIN = polygonAmoy;
const ADDRESSES = {
  NFT: '0xD60d95955370d90D2396F0F9907ebCFCC918e59d' as `0x${string}`,
  Market: '0x34F6c935641624c5F942244b34A852608a7da552' as `0x${string}`,
  SplitFactory: '0x7604F6BB0861731ABE8cE7B2e77d04bDA54ee693' as `0x${string}`,
}

const tus = createClient({
  rpcUrl: RPC_URL,
  chain: CHAIN,
  addresses: ADDRESSES,
});


function generateSimpleRandomBigInt(digitLength: number) {
  let randomString = String(Math.floor(Math.random() * 9) + 1);
  for (let i = 0; i < digitLength - 1; i++) {
    randomString += Math.floor(Math.random() * 10);
  }
  return BigInt(randomString);
}

const parentId = generateSimpleRandomBigInt(3);
const childId = generateSimpleRandomBigInt(3);

export default function App() {
  const [acct, setAcct] = useState<`0x${string}` | null>(null);
  const [originalMint, setOriginalMint] = useState<boolean>(false);

  async function connect() {
    const eth = (window as any).ethereum;
    if (!eth) return alert("Install Metamask");
    const [a] = await eth.request({ method: "eth_requestAccounts" });
    setAcct(a);
    tus.setAccount(a);
    alert(`Connected Account: ${a}`);
  }

  async function mintOriginal() {
    console.log("mintOriginal called. Current account:", acct);
    if (!acct) return;

    const publicClient = createPublicClient({
      chain: CHAIN,
      transport: http(RPC_URL),
    });

    
    try {
      alert("1. 원본 작품을 생성하고 NFT를 발행합니다.");
      console.log(
        "생성 작품 정보",
        "창작자:",
        acct,
        "/ 작품 아이디:",
        parentId
      );
      const createTxHash = await tus.nft.makeOriginalNFT({
        workId: parentId,
        amount: 3,
        split: "0x0000000000000000000000000000000000000000",
      });

      if (!createTxHash) {
        alert("트랜잭션 전송에 실패했습니다.");
        return;
      }

      alert("2. 트랜잭션이 채굴되기를 기다립니다...");
      const receipt = await tus.waitMining(createTxHash)

      console.log("트랜잭션 영수증", receipt);

      if (receipt.status === "success") {
        alert("3. 트랜잭션 성공!");
        setOriginalMint(true);
      } else {
        alert("트랜잭션이 실패했습니다.");
      }
    } catch (error: any) {
      console.error(error);
      const errorMessage = error?.shortMessage || error.message || '알 수 없는 에러 발생';
      alert(`에러가 발생했습니다: ${errorMessage}`);
    }
  }

  async function mintDerivativeBatch() {
    if (!acct) return;

    const publicClient = createPublicClient({
      chain: CHAIN,
      transport: http(RPC_URL),
    });

    const parentTokenIds = await getTokensOfWork(parentId, CHAIN, ADDRESSES.NFT);

    try {
      alert("1. 파생 작품을 생성하고 NFT를 발행합니다.");
      const createTxHash = await tus.nft.makeDerivativeNFT({
        parentTokenId: parentTokenIds[0],
        childWorkId: childId,
        upstreamBps: 3000,
        amount: 2
      });

      if (!createTxHash) {
        alert("트랜잭션 전송에 실패했습니다.");
        return;
      }

      alert("2. 트랜잭션이 채굴되기를 기다립니다...");
      const receipt = await publicClient.waitForTransactionReceipt({
        hash: createTxHash,
      });

      if (receipt.status === "success") {
        alert("3. 트랜잭션 성공!");
      } else {
        alert("트랜잭션이 실패했습니다.");
      }
    } catch (error: any) {
      console.error(error);
      const errorMessage = error?.shortMessage || error.message || '알 수 없는 에러 발생';
      alert(`에러가 발생했습니다: ${errorMessage}`);
    }
  }

  async function listFirstEdition() {
    if (!acct) return;

    const publicClient = createPublicClient({
      chain: CHAIN,
      transport: http(RPC_URL),
    });

    try {
      alert('1. 마켓에 대한 NFT 전송 권한을 확인하고, 필요시 승인 트랜잭션을 보냅니다.');
      const approvalTxHash = await tus.approvals.ensureApprovalAll({});

      if (approvalTxHash) {
        alert('2. 승인 트랜잭션이 채굴되기를 기다립니다...');
        const approvalReceipt = await publicClient.waitForTransactionReceipt({ hash: approvalTxHash });
        if (approvalReceipt.status !== 'success') {
          alert('승인 트랜잭션이 실패했습니다.');
          return;
        }
        alert('승인 성공! 이제 리스팅을 진행합니다.');
      } else {
        alert('이미 승인되어 있습니다. 리스팅을 진행합니다.');
      }

      const parentTokenIds = await getTokensOfWork(parentId, CHAIN, ADDRESSES.NFT);
      if (parentTokenIds.length === 0) {
        alert('리스팅할 토큰이 없습니다.');
        return;
      }else{
        console.log("원작 토큰 목록: ", parentTokenIds)
        console.log("원작 토큰 1st 에디션: ", parentTokenIds[0])
      }

      const listArgs = {
        nft: ADDRESSES.NFT as `0x${string}`,
        tokenId: parentTokenIds[0],
        priceWei: utils.toWei("0.1"),
        isPrimary: true,
      };
      console.log("Calling market.list with arguments:", listArgs);

      alert('3. 리스팅 트랜잭션을 보냅니다.');
      const listTxHash = await tus.market.list({
        ...listArgs,
      });

      if (!listTxHash) {
        alert('리스팅 트랜잭션 전송에 실패했습니다.');
        return;
      }

      alert('4. 리스팅 트랜잭션이 채굴되기를 기다립니다...');
      const listReceipt = await publicClient.waitForTransactionReceipt({ hash: listTxHash });

      if (listReceipt.status === 'success') {
        alert(`리스팅 완료: 토큰 #${parentTokenIds[0]}, 가격 0.1`);
      } else {
        alert('리스팅 트랜잭션이 실패했습니다.');
      }

    } catch (error: any) {
      console.error(error);
      const errorMessage = error?.shortMessage || error.message || '알 수 없는 에러 발생';
      alert(`에러가 발생했습니다: ${errorMessage}`);
    }
  }

  return (
    <div style={{ padding: 24, fontFamily: "system-ui" }}>
      <h1>TokenUS Minimal DApp</h1>
      <button onClick={connect}>{acct ? "Connected" : "Connect"}</button>
      <div style={{ marginTop: 12 }}>
        <button onClick={mintOriginal} disabled={!acct}>
          Mint Original Work + 3 Editions
        </button>
      </div>
      <div style={{ marginTop: 12 }}>
        <button onClick={mintDerivativeBatch} disabled={!acct || !originalMint}>
          Mint Derivative Work + 2 Editions
        </button>
      </div>
      <div style={{ marginTop: 12 }}>
        <button onClick={listFirstEdition} disabled={!acct  || !originalMint}>
          List Original Work NFT (Primary)
        </button>
      </div>
      <p style={{ marginTop: 16 }}>
        ※ 데모이므로 배포 주소/체인은 직접 설정하세요.
      </p>
    </div>
  );
}
