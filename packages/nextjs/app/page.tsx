"use client";

import Link from "next/link";
import type { NextPage } from "next";
import { AcademicCapIcon, UserGroupIcon, WrenchScrewdriverIcon } from "@heroicons/react/24/outline";

const Home: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col grow pt-16">
        {/* Hero Section */}
        <div className="px-5 max-w-4xl mx-auto text-center">
          <h1 className="mb-4">
            <span className="block text-5xl md:text-7xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              Sk33L
            </span>
          </h1>
          <p className="text-xl md:text-2xl text-base-content/80 mb-2">
            Web3 Education Platform
          </p>
          <p className="text-lg text-base-content/60 max-w-2xl mx-auto mb-12">
            Connect educators and learners on-chain. Subscribe monthly, complete courses, and earn reputation in the decentralized learning economy.
          </p>
        </div>

        {/* Main Action Cards */}
        <div className="flex flex-col md:flex-row gap-8 px-5 mb-16">
          <Link href="/educator" className="group">
            <div className="flex flex-col bg-base-100 px-10 py-12 text-center items-center w-80 rounded-3xl border-2 border-primary/20 hover:border-primary transition-all hover:shadow-xl hover:scale-105">
              <AcademicCapIcon className="h-16 w-16 text-primary mb-4" />
              <h2 className="text-2xl font-bold mb-3">I&apos;m an Educator</h2>
              <p className="text-base-content/70 mb-4">
                Create courses, manage subscriptions, and build your onchain reputation
              </p>
              <div className="px-6 py-2 bg-primary text-primary-content rounded-full font-semibold group-hover:bg-primary/90">
                Get Started →
              </div>
            </div>
          </Link>

          <Link href="/learner" className="group">
            <div className="flex flex-col bg-base-100 px-10 py-12 text-center items-center w-80 rounded-3xl border-2 border-secondary/20 hover:border-secondary transition-all hover:shadow-xl hover:scale-105">
              <UserGroupIcon className="h-16 w-16 text-secondary mb-4" />
              <h2 className="text-2xl font-bold mb-3">I&apos;m a Learner</h2>
              <p className="text-base-content/70 mb-4">
                Subscribe to educators, complete courses, and earn reputation rewards
              </p>
              <div className="px-6 py-2 bg-secondary text-secondary-content rounded-full font-semibold group-hover:bg-secondary/90">
                Start Learning →
              </div>
            </div>
          </Link>
        </div>

        {/* Debug Section */}
        <div className="w-full bg-base-300 px-8 py-12 mt-auto">
          <div className="max-w-4xl mx-auto">
            <div className="flex flex-col items-center text-center">
              <WrenchScrewdriverIcon className="h-10 w-10 text-accent mb-4" />
              <h3 className="text-xl font-bold mb-2">Developer Tools</h3>
              <p className="text-base-content/70 mb-4">
                Test and interact with the smart contracts directly
              </p>
              <Link 
                href="/debug" 
                className="btn btn-accent btn-sm"
              >
                Debug Contracts
              </Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
