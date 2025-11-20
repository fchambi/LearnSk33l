import React from "react";

interface CourseCardProps {
  courseId: bigint;
  metadataURI: string;
  isActive: boolean;
  isEducatorView: boolean;
  onToggleActive?: () => void;
  isToggling?: boolean;
}

export const CourseCard: React.FC<CourseCardProps> = ({
  courseId,
  metadataURI,
  isActive,
  isEducatorView,
  onToggleActive,
  isToggling = false,
}) => {
  return (
    <div className={`card bg-base-200 shadow-lg border ${isActive ? "border-success/50" : "border-base-300"}`}>
      <div className="card-body">
        <div className="flex justify-between items-start">
          <div>
            <h3 className="card-title text-lg">
              Course #{courseId.toString()}
            </h3>
            <div className={`badge ${isActive ? "badge-success" : "badge-ghost"} mt-2`}>
              {isActive ? "Active" : "Inactive"}
            </div>
          </div>
        </div>
        
        <div className="mt-3">
          <p className="text-xs text-base-content/60 font-mono break-all">
            {metadataURI}
          </p>
        </div>

        {isEducatorView && onToggleActive && (
          <div className="card-actions justify-end mt-4">
            <button
              className={`btn btn-sm ${isActive ? "btn-warning" : "btn-success"}`}
              onClick={onToggleActive}
              disabled={isToggling}
            >
              {isToggling ? (
                <span className="loading loading-spinner loading-xs"></span>
              ) : isActive ? (
                "Deactivate"
              ) : (
                "Activate"
              )}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

