'use client';

import Image from 'next/image';
import useMockData from '@/hooks/useMockData';
import NFTCard from '@/components/NFTCard';

const Dashboard = () => {
  const { getLocks, getNFTs } = useMockData();
  const locks = getLocks();
  const nfts = getNFTs();

  // Combine locks and NFTs data
  const nftsWithLocks = nfts.map(nft => {
    const relatedLock = locks.find(lock => lock.tokenId === nft.id);
    return {
      ...nft,
      lockDetails: relatedLock
    };
  });

  return (
    <div className="min-h-screen bg-neutral-800 text-neutral-100">
      <nav className="bg-neutral-700 border-b border-opacityLight-10">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center">
            <div className="flex items-center gap-3">
              <Image
                src="/assets/logo.svg"
                alt="Carbon Locker Logo"
                width={24}
                height={24}
                className="text-greenish-500 w-auto h-6"
                priority
              />
              <span className="text-xl font-semibold">Carbon Locker</span>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">My Carbon Certificates</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {nftsWithLocks.map((nft) => (
            <div key={nft.id} className="bg-neutral-700 rounded-lg p-6 hover:bg-neutral-600 transition-colors">
              <NFTCard
                id={nft.id}
                image={nft.image}
                description={nft.description}
                status={nft.status}
                lockAmount={nft.lockDetails?.amount}
                lockDuration={nft.lockDetails?.duration}
                lockStatus={nft.lockDetails?.status}
              />
            </div>
          ))}
        </div>
      </main>

      <footer className="bg-neutral-700 border-t border-opacityLight-10 mt-auto py-6">
        <div className="max-w-7xl mx-auto px-4 text-center text-neutral-300">
          <p>© 2024 Carbon Locker DApp. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default Dashboard;
