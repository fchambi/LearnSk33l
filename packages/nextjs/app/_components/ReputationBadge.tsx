import React from "react";

interface ReputationBadgeProps {
  score: bigint | undefined;
  label: string;
  isLoading: boolean;
}

export const ReputationBadge: React.FC<ReputationBadgeProps> = ({ score, label, isLoading }) => {
  return (
    <div className="flex flex-col items-center bg-base-200 rounded-xl p-6 shadow-lg border border-primary/20">
      <div className="text-sm font-semibold text-base-content/60 uppercase tracking-wide mb-2">{label}</div>
      {isLoading ? (
        <div className="loading loading-spinner loading-lg text-primary"></div>
      ) : (
        <div className="text-4xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
          {score?.toString() || "0"}
        </div>
      )}
      <div className="text-xs text-base-content/50 mt-2">Reputation Points</div>
    </div>
  );
};

