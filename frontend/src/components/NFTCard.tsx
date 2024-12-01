interface NFTCardProps {
  id: string;
  description: string;
  status: string;
  lockAmount?: number;
  lockDuration?: string;
  lockStatus?: string;
}

const NFTCard = ({ id, description, status, lockAmount, lockDuration, lockStatus }: NFTCardProps) => {
  return (
    <div className="flex flex-col h-full">
      <div className="aspect-square bg-neutral-600 rounded-lg mb-4">
        {/* NFT Image placeholder */}
      </div>
      <div className="flex flex-col gap-2">
        <h3 className="text-xl font-semibold">Certificate #{id}</h3>
        <p className="text-neutral-300">{description}</p>
        <div className="mt-auto pt-4">
          <div className="flex flex-col gap-1">
            <div className="flex justify-between">
              <span className="text-neutral-400">Amount:</span>
              <span>{lockAmount}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-neutral-400">Lock Duration:</span>
              <span>{lockDuration}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-neutral-400">Status:</span>
              <span className={`${status === 'Active' ? 'text-green-400' : 'text-yellow-400'}`}>
                {status}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NFTCard;
