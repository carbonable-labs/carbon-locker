import React from 'react';
import Link from "next/link";
import Image from "next/image";

const HomePage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white">
      
      <nav className="bg-gray-800 border-b border-gray-700">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center">
            <div className="flex items-center gap-3">
              <Image
                src="/assets/logo.svg"
                alt="Carbon Locker Logo"
                width={24}
                height={24}
                className="text-blue-500 w-auto h-6"
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
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Your secure platform for managing and trading carbon credits with transparency 
              and efficiency on the blockchain.
            </p>
          </div>

          
          <div className="grid md:grid-cols-3 gap-8 mb-12 max-w-4xl">
            <div className="p-6 bg-gray-800 rounded-lg border border-gray-700">
              <div className="text-2xl mb-4">🌱</div>
              <h3 className="text-lg font-semibold mb-2">Secure Storage</h3>
              <p className="text-gray-300">Safely store and manage your carbon credits in our digital locker system</p>
            </div>
            <div className="p-6 bg-gray-800 rounded-lg border border-gray-700">
              <div className="text-2xl mb-4">📊</div>
              <h3 className="text-lg font-semibold mb-2">Real-time Tracking</h3>
              <p className="text-gray-300">Monitor your carbon credit portfolio with advanced analytics</p>
            </div>
            <div className="p-6 bg-gray-800 rounded-lg border border-gray-700">
              <div className="text-2xl mb-4">🔄</div>
              <h3 className="text-lg font-semibold mb-2">Easy Trading</h3>
              <p className="text-gray-300">Seamlessly trade carbon credits on our decentralized platform</p>
            </div>
          </div>

          
          <div className="flex flex-col sm:flex-row gap-4">
            <Link 
              href="/locker" 
              className="px-8 py-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 
                         transition-colors duration-200 shadow-lg hover:shadow-xl text-lg font-semibold"
            >
              Access Locker
            </Link>
            <Link 
              href="/dashboard" 
              className="px-8 py-4 bg-green-600 text-white rounded-lg hover:bg-green-700 
                         transition-colors duration-200 shadow-lg hover:shadow-xl text-lg font-semibold"
            >
              View Dashboard
            </Link>
          </div>
        </div>
      </main>

      <footer className="bg-gray-800 border-t border-gray-700 mt-auto py-6">
        <div className="max-w-7xl mx-auto px-4 text-center text-gray-400">
          <p>© 2024 Carbon Locker DApp. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default HomePage;