import React, { useState } from "react";
import { useParams } from "react-router-dom";
import Web3 from "web3";
import Container from "../components/Container";
import Header from "../components/Header";

import VideoNFT from "../contracts/VideoNFT.json";

function VideoUpload() {
  const { menu } = useParams();

  const [videoFile, setVideoFile] = useState(null);
  const [videoPreview, setVideoPreview] = useState(null);
  const [minting, setMinting] = useState(false);
  const [NFTname, setNFTname] = useState("");
  const [NFTsymbol, setNFTsymbol] = useState("");
  const [totalSupply, setTotalSupply] = useState(1);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file && file.type.startsWith("video/")) {
      setVideoFile(file);
      setVideoPreview(URL.createObjectURL(file));
    } else {
      alert("영상 파일만 업로드할 수 있습니다.");
    }
  };

  const handleUpload = async () => {
    if (!videoFile) {
      alert("업로드할 파일을 선택해주세요.");
      return;
    }
    if (!NFTname || !NFTsymbol) {
      alert("NFT 이름과 심볼을 입력해주세요.");
      return;
    }

    try {
      if (window.ethereum) {
        const web3 = new Web3(window.ethereum);
        await window.ethereum.request({ method: "eth_requestAccounts" });

        const accounts = await web3.eth.getAccounts();
        const account = accounts[0];

        const networkId = await web3.eth.net.getId();
        const deployedNetwork = VideoNFT.networks[networkId];
        // const deployedNetwork = '0xCeF932F016Df7895EBe53977791669f0228a7Dba';
        console.log(networkId);

        if (!deployedNetwork) {
          alert("스마트 컨트랙트가 현재 네트워크에 배포되지 않았습니다.");
          return;
        }

        const contract = new web3.eth.Contract(
          VideoNFT.abi,
          deployedNetwork.address
        );

        setMinting(true);

        const metadataURI = 'https://TokenUs.s3.us-west-2.amazonaws.com/550e8400-e29b-41d4-a716-446655440000.mp4'
        // NFT 발행 트랜잭션 호출
        await contract.methods
          .mintVideoNFT(metadataURI, totalSupply, NFTname, NFTsymbol)
          .send({ from: account });

        alert("NFT가 성공적으로 발행되었습니다!");
        setMinting(false);
      } else {
        alert("MetaMask가 설치되어 있지 않습니다.");
      }
    } catch (error) {
      console.error("NFT 발행 오류:", error);
      alert("NFT 발행 중 오류가 발생했습니다.");
      setMinting(false);
    }
  };

  return (
    <Container>
      <Header menu={menu} />
      <div style={{ maxWidth: "500px", margin: "0 auto", textAlign: "center" }}>
        <input
          type="file"
          accept="video/*"
          onChange={handleFileChange}
          style={{ marginBottom: "10px" }}
        />

        {videoPreview && (
          <div style={{ margin: "20px 0" }}>
            <h4>미리보기:</h4>
            <video
              src={videoPreview}
              controls
              style={{ width: "100%", maxHeight: "300px" }}
            />
          </div>
        )}

        <input
          type="text"
          placeholder="NFT 이름"
          value={NFTname}
          onChange={(e) => setNFTname(e.target.value)}
          style={{ display: "block", margin: "10px auto", width: "100%" }}
        />
        <input
          type="text"
          placeholder="NFT 심볼"
          value={NFTsymbol}
          onChange={(e) => setNFTsymbol(e.target.value)}
          style={{ display: "block", margin: "10px auto", width: "100%" }}
        />
        <input
          type="number"
          placeholder="발행 수량"
          value={totalSupply}
          onChange={(e) => setTotalSupply(e.target.value)}
          min="1"
          style={{ display: "block", margin: "10px auto", width: "100%" }}
        />

        <button
          onClick={handleUpload}
          disabled={minting}
          style={{
            padding: "10px 20px",
            backgroundColor: minting ? "#ccc" : "#007bff",
            color: "#fff",
            border: "none",
            borderRadius: "5px",
            cursor: minting ? "not-allowed" : "pointer",
          }}
        >
          {minting ? "발행 중..." : "NFT 발행"}
        </button>
      </div>
    </Container>
  );
}

export default VideoUpload;
