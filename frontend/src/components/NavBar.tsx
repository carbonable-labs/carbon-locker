'use client';

import React from 'react';
import NavLink from './NavLink';
import WalletBar from './WalletBar';
import { Home, Lock, LayoutDashboard } from 'lucide-react';
import Image from 'next/image';

const navigation = [
  { name: 'Home', href: '/', icon: Home },
  { name: 'Locker', href: '/locker', icon: Lock },
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
];

const Navbar = () => {
  return (
    <nav className="bg-neutral-700 w-full sticky top-0 z-50">
      <div className="flex items-center justify-between py-3 px-20">
        <div className="flex items-center gap-3 cursor-pointer">
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

        <div className="flex items-center space-x-8">
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink key={item.name} href={item.href} className="flex items-center gap-2">
                <Icon className="w-4 h-4" />
                <span>{item.name}</span>
              </NavLink>
            );
          })}
        </div>

        <WalletBar />
      </div>
    </nav>
  );
};

export default Navbar;
