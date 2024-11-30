'use client';

import { Dialog, Transition } from '@headlessui/react';
import { Fragment } from 'react';
import { useConnect } from '@starknet-react/core';
import { X } from 'lucide-react';
import Image from 'next/image';

interface WalletModalProps {
  isOpen: boolean;
  setIsOpen: (isOpen: boolean) => void;
}

const walletIcons = {
  argentX: '/assets/wallets/argent.svg',
  braavos: '/assets/wallets/braavos.svg',
};

export function WalletModal({ isOpen, setIsOpen }: WalletModalProps) {
  const { connect, connectors } = useConnect();

  // Filter only Starknet wallets (Argent and Braavos)
  const starknetConnectors = connectors.filter(
    connector => connector.id === 'argentX' || connector.id === 'braavos'
  );

  const getWalletDetails = (id: string) => {
    switch (id) {
      case 'argentX':
        return {
          name: 'Argent X',
          icon: walletIcons.argentX,
        };
      case 'braavos':
        return {
          name: 'Braavos',
          icon: walletIcons.braavos,
        };
      default:
        return null;
    }
  };

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={() => setIsOpen(false)}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/50" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform rounded-2xl bg-[#1c1c1c] p-6 shadow-xl transition-all">
                <div className="flex justify-between items-center mb-6">
                  <Dialog.Title as="h3" className="text-xl font-semibold text-white">
                    Connect Your Wallet
                  </Dialog.Title>
                  <button
                    onClick={() => setIsOpen(false)}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                <div className="space-y-4">
                  {starknetConnectors.map((connector) => {
                    const walletDetails = getWalletDetails(connector.id);
                    if (!walletDetails) return null;
                    
                    return (
                      <button
                        key={connector.id}
                        onClick={() => {
                          connect({ connector });
                          setIsOpen(false);
                        }}
                        className="w-full flex items-center gap-3 p-4 rounded-lg
                          bg-[#2c2c2c] hover:bg-[#3c3c3c] transition-colors"
                      >
                        <div className="relative w-8 h-8">
                          <Image
                            src={walletDetails.icon}
                            alt={walletDetails.name}
                            width={32}
                            height={32}
                            className="rounded-md"
                          />
                        </div>
                        <span className="text-white font-medium">{walletDetails.name}</span>
                      </button>
                    );
                  })}

                  {starknetConnectors.length === 0 && (
                    <p className="text-gray-400 text-center">No Starknet wallets detected. Please install Argent X or Braavos.</p>
                  )}
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
}