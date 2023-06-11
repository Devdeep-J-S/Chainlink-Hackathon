import { ConnectButton, Logo } from "web3uikit";
import Link from "next/link";
import Image from "next/image";

export default function Header() {
  return (
    <main>
      <nav className="p-5 border-b-2 flex flex-row justify-between items-center">
        <h1 className="py-4 px-4 font-bold text-3xl">
          <Image
            src="/a.png"
            width={100}
            height={100}
            style={{ borderRadius: "30%" }}
            alt="daiict is great"
          />
          <Link href="/">
            <a className="py-4 px-4 font-bold text-3xl"> </a>
          </Link>
        </h1>
        <div className="flex flex-row items-center">
          <Link href="/">
            <a className="py-4 px-4 font-bold text-3xl">Home</a>
          </Link>
          <Link href="/sell-nft">
            <a className="py-4 px-4 font-bold text-3xl">Sell NFT</a>
          </Link>
          <ConnectButton moralisAuth={false} />
        </div>
      </nav>
      <div className=" title">NFT listed in the Bazaar</div>
    </main>
  );
}
