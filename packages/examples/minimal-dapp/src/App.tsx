import React, { useState } from "react";
import { createPublicClient, http } from "viem";
import { polygonAmoy } from "viem/chains";
import {
  nft,
  approvals,
  market,
  utils,
  addresses,
} from "../../../sdk/src/index";
import { getTokensOfWork } from "../../../sdk/src/nft";

const CHAIN = polygonAmoy;
// 배포 후 실제 주소로 교체하거나, SDK의 fromEnv/getAddresses 사용
const ADDR = {
  NFT: "0x7BC958539E32482F43a9E121d2f851D0DE0b5a5b",
  Market: "0xc43268dE3d3EAD9179148Ff533eaCf284Bd9Ad10",
  SplitFactory: "0x685DD7D24259861a3ECAa51fC6006a842684eB5a",
} as const;

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
  const [rpcUrl] = useState<string>("https://rpc-amoy.polygon.technology");

  async function connect() {
    const eth = (window as any).ethereum;
    if (!eth) return alert("Install Metamask");
    const [a] = await eth.request({ method: "eth_requestAccounts" });
    setAcct(a);
    alert(`Connected Account: ${a}`);
  }

  async function mintOriginal() {
    if (!acct) return;

    const publicClient = createPublicClient({
      chain: CHAIN,
      transport: http(rpcUrl),
    });

    try {
      alert("1. 원본 작품 생성 트랜잭션을 보냅니다.");
      console.log(
        "생성 작품 정보",
        "창작자:",
        acct,
        "/ 작품 아이디:",
        parentId
      );
      const createTxHash = await nft.createOriginalWork({
        rpcUrl,
        chain: CHAIN,
        account: acct,
        nft: ADDR.NFT as `0x${string}`,
        workId: parentId,
        creator: acct,
        split: "0x0000000000000000000000000000000000000000",
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
        alert("3. 트랜잭션 성공! 이제 에디션을 민팅합니다.");
        await nft.mintEditionBatch({
          rpcUrl,
          chain: CHAIN,
          account: acct,
          nft: ADDR.NFT as `0x${string}`,
          to: acct,
          workId: parentId,
          amount: 3,
        });
        alert("원본 작품 + 3개 에디션 민팅 완료!");
        setOriginalMint(true);
      } else {
        alert("트랜잭션이 실패했습니다.");
      }
    } catch (error) {
      console.error(error);
      alert("에러가 발생했습니다.");
    }
  }

  async function mintDerivativeBatch() {
    if (!acct) return;

    const publicClient = createPublicClient({
      chain: CHAIN,
      transport: http(rpcUrl),
    });

    const parentTokenIds = await getTokensOfWork(parentId, CHAIN, ADDR.NFT);

    try {
      alert("1. 파생 작품 생성 트랜잭션을 보냅니다.");
      const createTxHash = await nft.createDerivativeWork({
        rpcUrl,
        chain: CHAIN,
        account: acct,
        nft: ADDR.NFT as `0x${string}`,
        parentTokenId: parentTokenIds[0],
        childWorkId: childId,
        childCreator: acct,
        upstreamBps: 3000,
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
        alert("3. 트랜잭션 성공! 이제 파생 에디션을 민팅합니다.");
        await nft.mintDerivativeEditionBatch({
          rpcUrl,
          chain: CHAIN,
          account: acct,
          nft: ADDR.NFT as `0x${string}`,
          to: acct,
          childWorkId: childId,
          parentTokenId: parentTokenIds[0],
          amount: 2,
        });
        alert("파생 작품 + 2개 에디션 민팅 완료!");
      } else {
        alert("트랜잭션이 실패했습니다.");
      }
    } catch (error) {
      console.error(error);
      alert("에러가 발생했습니다.");
    }
  }

  async function listFirstEdition() {
    if (!acct) return;

    const publicClient = createPublicClient({
      chain: CHAIN,
      transport: http(rpcUrl),
    });

    try {
      alert('1. 마켓에 대한 NFT 전송 권한을 확인하고, 필요시 승인 트랜잭션을 보냅니다.');
      const approvalTxHash = await approvals.ensureApprovalAll({
        rpcUrl,
        chain: CHAIN,
        account: acct,
        nft: ADDR.NFT as `0x${string}`,
        operator: ADDR.Market as `0x${string}`,
      });

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

      const parentTokenIds = await getTokensOfWork(parentId, CHAIN, ADDR.NFT);
      if (parentTokenIds.length === 0) {
        alert('리스팅할 토큰이 없습니다.');
        return;
      }else{
        console.log("원작 토큰 목록: ", parentTokenIds)
        console.log("원작 토큰 1st 에디션: ", parentTokenIds[0])
      }

      const listArgs = {
        nft: ADDR.NFT as `0x${string}`,
        tokenId: parentTokenIds[0],
        priceWei: utils.toWei("0.1"),
        isPrimary: true,
      };
      console.log("Calling market.list with arguments:", listArgs);

      alert('3. 리스팅 트랜잭션을 보냅니다.');
      const listTxHash = await market.list({
        rpcUrl,
        chain: CHAIN,
        account: acct,
        market: ADDR.Market as `0x${string}`,
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
