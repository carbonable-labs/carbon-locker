import React, { useState } from 'react';
import { Lock, Coins, Calendar, CheckCircle, XCircle } from 'lucide-react';
import "../app/globals.css";


const LockForm = ({ onSubmit }: { onSubmit: (data: { tokenId: string; amount: number; duration: number }) => void }) => {
  const [formData, setFormData] = useState({
    tokenId: '',
    amount: '',
    duration: ''
  });
  const [isModalOpen, setIsModalOpen] = useState(false);


  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };


  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsModalOpen(true);
  };


  const confirmSubmission = () => {
    onSubmit({
      tokenId: formData.tokenId,
      amount: Number(formData.amount),
      duration: Number(formData.duration)
    });
    setIsModalOpen(false);
    setFormData({ tokenId: '', amount: '', duration: '' });
  };


  // Sample current locks data
  const currentLocks = [
    {
      tokenId: '1001',
      credits: 50,
      duration: 30,
      status: 'Locked'
    },
    {
      tokenId: '1002',
      credits: 100,
      duration: 60,
      status: 'Offsettable'
    }
  ];


  return (
    <div className="min-h-screen p-4 Locker flex justify-center items-center">
      <div className="w-full max-w-md mx-auto">
        <div className="bg-opacityLight-5 backdrop-blur-md rounded-2xl shadow-2xl p-8 mb-4 border border-opacityLight-10">
          <header className="text-center mb-6">
            <div className="inline-flex items-center gap-3">
              <Lock className="text-greenish-500" size={32} />
              <h2 className="text-2xl font-bold text-neutral-100">Token Locker</h2>
            </div>
          </header>


          <form onSubmit={handleSubmit} className="space-y-4">
            <InputField
              icon={<Coins className="text-greenish-500" size={20} />}
              label="Token ID"
              labelClassName="text-neutral-300" // Custom class for the label
              type="text"
              name="tokenId"
              value={formData.tokenId}
              onChange={handleChange}
              placeholder="Enter Token ID"
            />


            <InputField
              icon={<Coins className="text-greenish-500" size={20} />}
              label="Amount"
               labelClassName="text-neutral-300"
              type="number"
              name="amount"
              value={formData.amount}
              onChange={handleChange}
              min="1"
              placeholder="Enter Token Amount"
            />


            <InputField
              icon={<Calendar className="text-greenish-500" size={20} />}
              label="Lock Duration (days)"
               labelClassName="text-neutral-300"
              type="number"
              name="duration"
              value={formData.duration}
              onChange={handleChange}
              min="1"
              placeholder="Enter Lock Duration"
            />


            <button
              type="submit"
              className="w-full bg-greenish-500 text-white py-2 rounded-md hover:bg-[#1c2432] transition-colors grid place-items-center"
            >
              <div className="inline-flex items-center gap-2 opacity-">
                <Lock size={20} />
                Lock Tokens
              </div>
            </button>
          </form>
        </div>


        {/* Current Locks Section */}
        <div className="bg-opacityLight-5 border border-opacityLight-10 rounded-xl p-4 space-y-3">
          <h3 className="text-neutral-100 font-medium mb-2">Current Locks</h3>
          {currentLocks.map((lock) => (
            <div
              key={lock.tokenId}
              className="bg-[rgb(11,13,19)] rounded-lg p-3 flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <Lock className="text-neutral-100" size={20} />
                <div>
                  <p className="text-neutral-100">
                    Token {lock.tokenId}: {lock.credits} credits locked for {lock.duration} days
                  </p>
                  <p className="text-sm text-neutral-300">({lock.status})</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>


      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 grid place-items-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md shadow-2xl">
            <div className="text-center space-y-4">
              <CheckCircle className="mx-auto text-green-500" size={48} />
              <h3 className="text-xl font-bold">Confirm Token Lock</h3>


              <div className="text-left space-y-2 py-4">
                <p><strong>Token ID:</strong> {formData.tokenId}</p>
                <p><strong>Amount:</strong> {formData.amount}</p>
                <p><strong>Duration:</strong> {formData.duration} days</p>
              </div>


              <div className="grid grid-cols-2 gap-4">
                <button
                  onClick={confirmSubmission}
                  className="bg-greenish-500 text-white py-2 rounded-md hover:bg-green-600 transition-colors inline-flex items-center justify-center gap-2"
                >
                  <CheckCircle size={20} />
                  Confirm
                </button>
                <button
                  onClick={() => setIsModalOpen(false)}
                  className="bg-red-500 text-white py-2 rounded-md hover:bg-red-600 transition-colors inline-flex items-center justify-center gap-2"
                >
                  <XCircle size={20} />
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};


const InputField = ({
  icon,
  label,
  labelClassName,
  ...inputProps
}: React.InputHTMLAttributes<HTMLInputElement> & {
  icon: React.ReactNode,
  label: string,
  labelClassName?: string
}) => (
  <div>
    <label className={`flex items-center gap-2 text-sm font-medium mb-2 ${labelClassName}`}>
      {icon}
      {label}
    </label>
    <input
      {...inputProps}
      required
      className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
    />
  </div>
);


export default LockForm;