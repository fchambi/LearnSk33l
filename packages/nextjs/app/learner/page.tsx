"use client";

import { useState } from "react";
import { Address } from "@scaffold-ui/components";
import type { NextPage } from "next";
import { formatEther } from "viem";
import { useAccount } from "wagmi";
import { AcademicCapIcon, UserGroupIcon, CheckCircleIcon } from "@heroicons/react/24/outline";
import { CourseCard } from "../_components/CourseCard";
import { ReputationBadge } from "../_components/ReputationBadge";
import { useScaffoldReadContract, useScaffoldWriteContract, useScaffoldEventHistory } from "~~/hooks/scaffold-eth";

// Demo educator addresses (Anvil default accounts 1 and 2)
const DEMO_EDUCATORS = [
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8" as `0x${string}`, // Anvil account #1
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" as `0x${string}`, // Anvil account #2
];

const LearnerPage: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [selectedEducator, setSelectedEducator] = useState<`0x${string}`>(DEMO_EDUCATORS[0]);
  const [subscriptionMonths, setSubscriptionMonths] = useState(1);
  const [courseIdToComplete, setCourseIdToComplete] = useState("");
  const [courseScore, setCourseScore] = useState("");

  // Read learner reputation
  const { data: reputation, isLoading: reputationLoading } = useScaffoldReadContract({
    contractName: "Reputation",
    functionName: "learnerScore",
    args: [connectedAddress],
  });

  // Get all course events
  const { data: allCourseEvents } = useScaffoldEventHistory({
    contractName: "CourseRegistry",
    eventName: "CourseCreated",
    fromBlock: 0n,
    watch: true,
  });

  // Filter courses by selected educator
  const educatorCourses = allCourseEvents?.filter(event => event.args.educator === selectedEducator) || [];

  // Write contracts
  const { writeContractAsync: writeSubscription } = useScaffoldWriteContract({
    contractName: "EducatorSubscription",
  });

  const { writeContractAsync: writeLearnToEarn } = useScaffoldWriteContract({
    contractName: "LearnToEarn",
  });

  const handleSubscribe = async (educator: `0x${string}`, plan: any) => {
    try {
      const monthlyPrice = plan[0] as bigint;
      const totalPrice = monthlyPrice * BigInt(subscriptionMonths);

      await writeSubscription({
        functionName: "subscribe",
        args: [educator, BigInt(subscriptionMonths)],
        value: totalPrice,
      });
    } catch (error) {
      console.error("Error subscribing:", error);
    }
  };

  const handleCompleteCourse = async () => {
    try {
      const courseId = BigInt(courseIdToComplete);
      const score = BigInt(courseScore);

      if (score < 70n) {
        alert("Score must be at least 70 to complete the course");
        return;
      }

      await writeLearnToEarn({
        functionName: "completeCourse",
        args: [courseId, score],
      });

      setCourseIdToComplete("");
      setCourseScore("");
    } catch (error) {
      console.error("Error completing course:", error);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="mb-8">
        <h1 className="text-4xl font-bold mb-4 bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
          Learner Dashboard
        </h1>
        <div className="flex items-center gap-2">
          <span className="text-base-content/60">Your Address:</span>
          <Address address={connectedAddress} />
        </div>
      </div>

      {/* Reputation Section */}
      <div className="mb-8">
        <ReputationBadge score={reputation} label="Learner Reputation" isLoading={reputationLoading} />
      </div>

      {/* Educators Section */}
      <div className="card bg-base-200 shadow-xl mb-8">
        <div className="card-body">
          <h2 className="card-title flex items-center gap-2">
            <UserGroupIcon className="w-6 h-6 text-primary" />
            Available Educators
          </h2>

          <div className="space-y-4 mt-4">
            {DEMO_EDUCATORS.map(educator => (
              <EducatorCard
                key={educator}
                educator={educator}
                student={connectedAddress}
                subscriptionMonths={subscriptionMonths}
                onSubscribe={handleSubscribe}
              />
            ))}
          </div>

          <div className="divider"></div>

          <div className="form-control w-full max-w-xs">
            <label className="label">
              <span className="label-text">Subscription Duration</span>
            </label>
            <select
              className="select select-bordered"
              value={subscriptionMonths}
              onChange={e => setSubscriptionMonths(Number(e.target.value))}
            >
              {Array.from({ length: 12 }, (_, i) => i + 1).map(month => (
                <option key={month} value={month}>
                  {month} {month === 1 ? "month" : "months"}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Course Browser */}
      <div className="card bg-base-200 shadow-xl mb-8">
        <div className="card-body">
          <h2 className="card-title flex items-center gap-2">
            <AcademicCapIcon className="w-6 h-6 text-secondary" />
            Browse Courses
          </h2>

          <div className="form-control w-full max-w-xs mb-4">
            <label className="label">
              <span className="label-text">Select Educator</span>
            </label>
            <select
              className="select select-bordered"
              value={selectedEducator}
              onChange={e => setSelectedEducator(e.target.value as `0x${string}`)}
            >
              {DEMO_EDUCATORS.map(educator => (
                <option key={educator} value={educator}>
                  {educator.slice(0, 6)}...{educator.slice(-4)}
                </option>
              ))}
            </select>
          </div>

          {educatorCourses.length === 0 ? (
            <div className="alert">
              <span>No courses available from this educator yet.</span>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {educatorCourses.map(event => (
                <CourseCard
                  key={event.args.courseId?.toString()}
                  courseId={event.args.courseId!}
                  metadataURI={event.args.metadataURI!}
                  isActive={true}
                  isEducatorView={false}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Complete Course */}
      <div className="card bg-base-200 shadow-xl mb-8">
        <div className="card-body">
          <h2 className="card-title flex items-center gap-2">
            <CheckCircleIcon className="w-6 h-6 text-success" />
            Complete a Course
          </h2>

          <div className="alert alert-info mb-4">
            <span className="text-sm">
              Note: You must have an active subscription to the educator and score at least 70 to complete a course.
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-control">
              <label className="label">
                <span className="label-text">Course ID</span>
              </label>
              <input
                type="number"
                placeholder="1"
                className="input input-bordered"
                value={courseIdToComplete}
                onChange={e => setCourseIdToComplete(e.target.value)}
                min="1"
              />
            </div>

            <div className="form-control">
              <label className="label">
                <span className="label-text">Your Score (0-100)</span>
              </label>
              <input
                type="number"
                placeholder="85"
                className="input input-bordered"
                value={courseScore}
                onChange={e => setCourseScore(e.target.value)}
                min="0"
                max="100"
              />
            </div>
          </div>

          <div className="card-actions justify-end mt-4">
            <button className="btn btn-success" onClick={handleCompleteCourse}>
              Complete Course
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// Educator Card Component
const EducatorCard = ({
  educator,
  student,
  subscriptionMonths,
  onSubscribe,
}: {
  educator: `0x${string}`;
  student: `0x${string}` | undefined;
  subscriptionMonths: number;
  onSubscribe: (educator: `0x${string}`, plan: any) => void;
}) => {
  // Read subscription plan for educator
  const { data: plan } = useScaffoldReadContract({
    contractName: "EducatorSubscription",
    functionName: "plans",
    args: [educator],
  });

  // Check if student is subscribed
  const { data: isSubscribed } = useScaffoldReadContract({
    contractName: "EducatorSubscription",
    functionName: "isSubscribed",
    args: student ? [student, educator] : undefined,
  });

  if (!plan) return null;

  const monthlyPrice = formatEther(plan[0] as bigint);
  const isPlanActive = plan[1] as boolean;
  const totalPrice = parseFloat(monthlyPrice) * subscriptionMonths;

  return (
    <div className="card bg-base-300 border border-base-content/10">
      <div className="card-body">
        <div className="flex justify-between items-start mb-2">
          <Address address={educator} />
          <div className={`badge ${isSubscribed ? "badge-success" : "badge-ghost"}`}>
            {isSubscribed ? "Subscribed" : "Not Subscribed"}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 my-2">
          <div>
            <div className="text-sm text-base-content/60">Monthly Price</div>
            <div className="text-lg font-bold text-primary">{monthlyPrice} ETH</div>
          </div>
          <div>
            <div className="text-sm text-base-content/60">Status</div>
            <div className={`text-lg font-bold ${isPlanActive ? "text-success" : "text-error"}`}>
              {isPlanActive ? "Active" : "Inactive"}
            </div>
          </div>
        </div>

        {isPlanActive && !isSubscribed && (
          <div className="card-actions justify-end">
            <button className="btn btn-primary btn-sm" onClick={() => onSubscribe(educator, plan)}>
              Subscribe ({totalPrice.toFixed(4)} ETH for {subscriptionMonths} {subscriptionMonths === 1 ? "month" : "months"})
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default LearnerPage;

