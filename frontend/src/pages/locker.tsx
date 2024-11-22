import React, { useState } from "react";
import LockForm from "../components/LockForm";
import useMockData from "../hooks/useMockData";


const LockerPage = () => {
  const { getLocks } = useMockData();
  const [locks, setLocks] = useState(getLocks());


  const handleLockSubmit = (lockData: {
    tokenId: string;
    amount: number;
    duration: number;
  }) => {
    const newLock = {
      id: (locks.length + 1).toString(),
      tokenId: lockData.tokenId,
      amount: lockData.amount,
      duration: `${lockData.duration} days`,
      status: "Locked",
    };
    setLocks([...locks, newLock]);
  };


  return (
    <div className="p-4 bg-neutral-800">
      <h1 className="text-neutral-100">Lock Your Carbon Credits</h1>
      <LockForm onSubmit={handleLockSubmit} />
    </div>
  );
};


export default LockerPage;