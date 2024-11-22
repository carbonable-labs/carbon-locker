import React from 'react';
import Link from "next/link";
import Image from "next/image";

const HomePage = () => {
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

      <main className="max-w-7xl mx-auto px-4 py-16">
        <div className="flex flex-col items-center text-center">
          <div className="mb-16">
            <h1 className="text-5xl font-bold mb-6">
              Welcome to Carbon Locker
            </h1>
            <p className="text-xl text-neutral-300 max-w-2xl mx-auto mb-8">
              Your secure platform for managing and trading carbon credits with transparency
              and efficiency on the blockchain.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 mb-12 max-w-4xl">
            <div className="p-6 bg-neutral-700 rounded-lg border border-opacityLight-10">
              <div className="text-2xl mb-4">🌱</div>
              <h3 className="text-lg font-semibold mb-2">Secure Storage</h3>
              <p className="text-neutral-300">Safely store and manage your carbon credits in our digital locker system</p>
            </div>
            <div className="p-6 bg-neutral-700 rounded-lg border border-opacityLight-10">
              <div className="text-2xl mb-4">📊</div>
              <h3 className="text-lg font-semibold mb-2">Real-time Tracking</h3>
              <p className="text-neutral-300">Monitor your carbon credit portfolio with advanced analytics</p>
            </div>
            <div className="p-6 bg-neutral-700 rounded-lg border border-opacityLight-10">
              <div className="text-2xl mb-4">🔄</div>
              <h3 className="text-lg font-semibold mb-2">Easy Trading</h3>
              <p className="text-neutral-300">Seamlessly trade carbon credits on our decentralized platform</p>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-4">
            <Link
              href="/locker"
              className="px-8 py-4 bg-greenish-500 text-white rounded-lg hover:bg-greenish-600 
                        transition-colors duration-200 shadow-lg hover:shadow-xl text-lg font-semibold"
            >
              Access Locker
            </Link>
            <Link
              href="/dashboard"
              className="px-8 py-4 bg-greenish-500 text-white rounded-lg hover:bg-greenish-600 
                        transition-colors duration-200 shadow-lg hover:shadow-xl text-lg font-semibold"
            >
              View Dashboard
            </Link>
          </div>
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

export default HomePage;