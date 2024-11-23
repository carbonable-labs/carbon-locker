const useMockData = () => {
  const getLocks = () => [
    { id: "1", tokenId: "1001", amount: 50, duration: "30 days", status: "Locked" },
    { id: "2", tokenId: "1002", amount: 100, duration: "60 days", status: "Offsettable" },
    { id: "3", tokenId: "1003", amount: 100, duration: "60 days", status: "Offsettable" },
  ];

  const getNFTs = () => [
    { id: "1001", lockId: "1", description: "50 tokens locked for 30 days", status: "Active" },
    { id: "1002", lockId: "2", description: "100 tokens locked for 60 days", status: "Archived" },
    { id: "1003", lockId: "3", description: "100 tokens locked for 60 days", status: "Archived" },
  ];

  return { getLocks, getNFTs };
};

export default useMockData;
