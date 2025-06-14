# 🪙TokenUs🪙
- 이화여자대학교 컴퓨터공학과 캡스톤디자인과창업프로젝트A,B
- 개발 기간: 2024.09 ~ 2025.06

## Team Info : 8시 스쿼시 연맹
| 안희재 | 서지민 | 김원영 |
| --- | --- | --- |
| @AnyJae | @SeoJimin1234    | @lasagna10 |
| -FE 개발<br>-SmartContract개발 | -BE 개발<br>-ML 개발<br>-SmartContract 개발| -UX/UI 디자인<br>-FE개발<br>-SmartContract 개발 |


## Project Info
 영상을 NFT로 발행하여 영상의 고유 가치를 지키고, 불법 복제를 방지하며, 원저작자의 권리를 보호하고 투자의 기회까지 제공하는 영상 플랫폼.
#### [주요 기능1 - 영상 유사도 검사]
사전 학습된 ResNet-50 모델과 Cosine Similarity를 활용한 유사도 검사. 영상의 고유성과 NFT의 가치를 보호하고, 불법 복제 방지.
#### [주요 기능2 - NFT 발행]
Ethereum을 기반으로 한 NFT 발행
#### [주요 기능3 - NFT 거래]
유저 간 자유로운 NFT 거래. 수익을 기대할 수 있음

---

## How to Use
#### 0. .env 파일 작성

```
MNEMONIC=
PROJECT_ID=
PRIVATE_KEY=
```

#### 1. truffle 설치

```
npm install truffle
```

#### 2. ganache 설치

```
npm install ganache
```

#### 3. Package 설치
```
npm install
```

#### 3. Package 설치
```
npm install
```
#### 4. 스마트 컨트랙트 컴파일
```
truffle compile
```
#### 5. 스마트 컨트랙트 배포
```
truffle migreate --network <<배포할 네트워크>>
```
