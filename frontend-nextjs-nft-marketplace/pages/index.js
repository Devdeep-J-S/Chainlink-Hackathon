import styles from "../styles/Home.module.css";
import { useMoralis } from "react-moralis";
import NFTBox from "../components/NFTBox";
import networkMapping from "../constants/networkMapping.json";
import GET_ACTIVE_ITEMS from "../constants/subgraphQueries";
import { useQuery } from "@apollo/client";

export default function Home() {
  const { chainId, isWeb3Enabled } = useMoralis();
  const chainString = chainId ? parseInt(chainId).toString() : null;
  const marketplaceAddress = chainId
    ? networkMapping[chainString].NftMarketplace[0]
    : null;

  const { loading, error, data: listedNfts } = useQuery(GET_ACTIVE_ITEMS);

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="font-ROBERTO text-m lg:flex title">
        NFT listed in the Bazaar
      </div>
      <div className="container mx-auto">
        <div className="flex flex-wrap">
          {isWeb3Enabled && chainId ? (
            loading || !listedNfts ? (
              <div>Loading...</div>
            ) : (
              listedNfts.activeItems.map((nft) => {
                const { price, nftAddress, tokenId, seller } = nft;
                return marketplaceAddress ? (
                  <NFTBox
                    price={price}
                    nftAddress={nftAddress}
                    tokenId={tokenId}
                    marketplaceAddress={marketplaceAddress}
                    seller={seller}
                    key={`${nftAddress}${tokenId}`}
                  />
                ) : (
                  <div>
                    Network error, please switch to a supported network.{" "}
                  </div>
                );
              })
            )
          ) : (
            <div>
              {" "}
              <p> </p>Please Connect your Wallet
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
