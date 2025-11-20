"use client";

import { useState } from "react";
import { Address } from "@scaffold-ui/components";
import type { NextPage } from "next";
import { formatEther, parseEther } from "viem";
import { useAccount } from "wagmi";
import { AcademicCapIcon, CurrencyDollarIcon } from "@heroicons/react/24/outline";
import { CourseCard } from "../_components/CourseCard";
import { ReputationBadge } from "../_components/ReputationBadge";
import { useScaffoldReadContract, useScaffoldWriteContract, useScaffoldEventHistory } from "~~/hooks/scaffold-eth";

const EducatorPage: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [monthlyPrice, setMonthlyPrice] = useState("");
  const [metadataURI, setMetadataURI] = useState("");

  // Read educator reputation
  const { data: reputation, isLoading: reputationLoading } = useScaffoldReadContract({
    contractName: "Reputation",
    functionName: "educatorScore",
    args: [connectedAddress],
  });

  // Read subscription plan
  const { data: subscriptionPlan } = useScaffoldReadContract({
    contractName: "EducatorSubscription",
    functionName: "plans",
    args: [connectedAddress],
  });

  // Get courses created by this educator
  const { data: courseEvents } = useScaffoldEventHistory({
    contractName: "CourseRegistry",
    eventName: "CourseCreated",
    fromBlock: 0n,
    watch: true,
  });

  // Filter courses by educator
  const myCourses = courseEvents?.filter(event => event.args.educator === connectedAddress) || [];

  // Write contracts
  const { writeContractAsync: writeSubscription } = useScaffoldWriteContract({
    contractName: "EducatorSubscription",
  });

  const { writeContractAsync: writeCourseRegistry } = useScaffoldWriteContract({
    contractName: "CourseRegistry",
  });

  const handleSetPrice = async () => {
    try {
      if (!monthlyPrice || parseFloat(monthlyPrice) <= 0) {
        alert("Please enter a valid price");
        return;
      }
      await writeSubscription({
        functionName: "setMonthlyPrice",
        args: [parseEther(monthlyPrice)],
      });
      setMonthlyPrice("");
    } catch (error) {
      console.error("Error setting price:", error);
    }
  };

  const handlePausePlan = async () => {
    try {
      await writeSubscription({
        functionName: "pausePlan",
      });
    } catch (error) {
      console.error("Error pausing plan:", error);
    }
  };

  const handleCreateCourse = async () => {
    try {
      if (!metadataURI.trim()) {
        alert("Please enter a metadata URI");
        return;
      }
      await writeCourseRegistry({
        functionName: "createCourse",
        args: [metadataURI],
      });
      setMetadataURI("");
    } catch (error) {
      console.error("Error creating course:", error);
    }
  };

  const handleToggleCourseActive = async (courseId: bigint, currentStatus: boolean) => {
    try {
      await writeCourseRegistry({
        functionName: "setCourseActive",
        args: [courseId, !currentStatus],
      });
    } catch (error) {
      console.error("Error toggling course:", error);
    }
  };

  const currentPrice = subscriptionPlan ? formatEther(subscriptionPlan[0] as bigint) : "0";
  const isPlanActive = subscriptionPlan ? (subscriptionPlan[1] as boolean) : false;

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="mb-8">
        <h1 className="text-4xl font-bold mb-4 bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
          Educator Dashboard
        </h1>
        <div className="flex items-center gap-2">
          <span className="text-base-content/60">Your Address:</span>
          <Address address={connectedAddress} />
        </div>
      </div>

      {/* Reputation Section */}
      <div className="mb-8">
        <ReputationBadge score={reputation} label="Educator Reputation" isLoading={reputationLoading} />
      </div>

      {/* Subscription Plan Management */}
      <div className="card bg-base-200 shadow-xl mb-8">
        <div className="card-body">
          <h2 className="card-title flex items-center gap-2">
            <CurrencyDollarIcon className="w-6 h-6 text-primary" />
            Subscription Plan
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 my-4">
            <div className="stat bg-base-300 rounded-lg">
              <div className="stat-title">Monthly Price</div>
              <div className="stat-value text-primary">{currentPrice} ETH</div>
            </div>
            <div className="stat bg-base-300 rounded-lg">
              <div className="stat-title">Status</div>
              <div className={`stat-value ${isPlanActive ? "text-success" : "text-error"}`}>
                {isPlanActive ? "Active" : "Paused"}
              </div>
            </div>
          </div>

          <div className="divider"></div>

          <div className="form-control w-full">
            <label className="label">
              <span className="label-text">Set Monthly Price (ETH)</span>
            </label>
            <div className="flex gap-2">
              <input
                type="number"
                placeholder="0.01"
                className="input input-bordered flex-1"
                value={monthlyPrice}
                onChange={e => setMonthlyPrice(e.target.value)}
                step="0.001"
                min="0"
              />
              <button className="btn btn-primary" onClick={handleSetPrice}>
                Set Price
              </button>
            </div>
          </div>

          <div className="card-actions justify-end mt-4">
            <button className="btn btn-warning" onClick={handlePausePlan}>
              {isPlanActive ? "Pause Plan" : "Plan Already Paused"}
            </button>
          </div>
        </div>
      </div>

      {/* Course Creation */}
      <div className="card bg-base-200 shadow-xl mb-8">
        <div className="card-body">
          <h2 className="card-title flex items-center gap-2">
            <AcademicCapIcon className="w-6 h-6 text-secondary" />
            Create New Course
          </h2>

          <div className="form-control w-full">
            <label className="label">
              <span className="label-text">Metadata URI</span>
            </label>
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="ipfs://Qm..."
                className="input input-bordered flex-1"
                value={metadataURI}
                onChange={e => setMetadataURI(e.target.value)}
              />
              <button className="btn btn-secondary" onClick={handleCreateCourse}>
                Create Course
              </button>
            </div>
            <label className="label">
              <span className="label-text-alt">Enter IPFS URI or any metadata link for your course</span>
            </label>
          </div>
        </div>
      </div>

      {/* Course List */}
      <div className="mb-8">
        <h2 className="text-2xl font-bold mb-4">Your Courses ({myCourses.length})</h2>
        {myCourses.length === 0 ? (
          <div className="alert">
            <span>No courses created yet. Create your first course above!</span>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {myCourses.map(event => (
              <CourseCard
                key={event.args.courseId?.toString()}
                courseId={event.args.courseId!}
                metadataURI={event.args.metadataURI!}
                isActive={true} // Will be updated when we read from contract
                isEducatorView={true}
                onToggleActive={() => handleToggleCourseActive(event.args.courseId!, true)}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default EducatorPage;

