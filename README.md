Folding@Home Desktop Client
===========================

Folding@home is a distributed computing project -- people from
throughout the world download and run software to band together to
make one of the largest supercomputers in the world. Every computer
takes the project closer to our goals. Folding@home uses novel
computational methods coupled to distributed computing, to simulate
problems millions of times more challenging than previously achieved.

Protein folding is linked to disease, such as Alzheimer's, ALS,
Huntington's, Parkinson's disease, and many Cancers.

Moreover, when proteins do not fold correctly (i.e. "misfold"), there
can be serious consequences, including many well known diseases, such
as Alzheimer's, Mad Cow (BSE), CJD, ALS, Huntington's, Parkinson's
disease, and many Cancers and cancer-related syndromes.

# What is protein folding?
Proteins are biology's workhorses -- its "nanomachines." Before
proteins can carry out these important functions, they assemble
themselves, or "fold." The process of protein folding, while critical
and fundamental to virtually all of biology, in many ways remains a
mystery.

# Quick Start for Debian Linux

## Install the Prerequisites
```
sudo apt-get update
sudo apt-get install -y scons git npm build-essential libssl-dev
```

## Get the code
```
git clone https://github.com/cauldrondevelopmentllc/cbang
git clone https://github.com/foldingathome/fah-client-bastet
git clone https://github.com/foldingathome/fah-web-client-bastet
```

## Build and Install the Folding@home Client
```
export CBANG_HOME=$PWD/cbang
scons -C cbang
scons -C fah-client-bastet package
sudo dpkg -i fah-client-bastet/*.deb
```

## Start the development web server
```
cd fah-web-client
npm i
npm run dev
```

## Open the Browser

With the development server running visit http://localhost:3000/
