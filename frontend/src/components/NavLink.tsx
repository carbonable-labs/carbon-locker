'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ReactNode } from 'react';

interface NavLinkProps {
  href: string;
  children: ReactNode;
  className?: string;
}

const NavLink = ({ href, children, className = '' }: NavLinkProps) => {
  const pathname = usePathname();
  const isActive = pathname === href;

  return (
    <Link
      href={href}
      className={`${className} ${
        isActive ? 'text-greenish-500 font-medium' : 'text-neutral-100 hover:text-greenish-500'
      } transition-colors duration-200`}
    >
      {children}
    </Link>
  );
};

export default NavLink;
