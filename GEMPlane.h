//*-- Author:  Ole Hansen<mailto:ole@jlab.org>; Jefferson Lab; 11-Jan-2010
//
#ifndef ROOT_TreeSearch_GEMPlane
#define ROOT_TreeSearch_GEMPlane

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
// TreeSearch::GEMPlane                                                      //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

#include "Plane.h"
#include "TBits.h"
#include <vector>
#include <map>
#include "SimDecoder.h"
#include "TH1.h"
#include "TH2.h"
#include "TCanvas.h"
//#include "GEMHit.h"

namespace TreeSearch {



  struct StripData_t {
    Float_t maxAdc;
    Float_t adcSum;
    Int_t maxTimeSample;//=-1;
    Double_t peaktime;// = 0;
    std::vector<Float_t> vADC;
    Bool_t  pass;
  StripData_t() : maxAdc(0), adcSum(0), maxTimeSample(-1), peaktime(0), vADC(0), pass(false)
 {}
  StripData_t( Float_t _raw, Float_t _adc, Int_t max_bin, Double_t _time, Bool_t _pass, std::vector<Float_t> _vADC )
  : maxAdc(_raw), adcSum(_adc), maxTimeSample(max_bin), peaktime(_time), vADC(_vADC), pass(_pass) {}
  };

  class GEMPlane : public Plane {
  public:
    GEMPlane( const char* name, const char* description = "",
	      THaDetectorBase* parent = 0 );
    // For ROOT RTTI
    GEMPlane() : fADCraw(0), fADC(0), fHitTime(0), fADCcor(0), fGoodHit(0) {}
    virtual ~GEMPlane();
    // TCanvas *c1;
    virtual void    Clear( Option_t* opt="" );
    virtual Int_t   Decode( const THaEvData& );
    virtual void    Print( Option_t* opt="" ) const;

    virtual Int_t   Begin( THaRunBase* r=0 );
    virtual Int_t   End( THaRunBase* r=0 );

    Double_t        GetAmplSigma( Double_t ampl ) const;
    Double_t        GetHitOcc()      const { return fHitOcc; }
    Double_t        GetOccupancy()   const { return fOccupancy; }
    Int_t           GetNsigStrips()  const { return fSigStrips.size(); }
    //StripData_t GEMChargeDep( const vector<Float_t>& amp );
    bool            AnalyzeStrip(const std::vector<Float_t>& amp, StripData_t &stripdata);
  protected:
    typedef std::vector<bool>  Vbool_t;

    // Hardware channel mapping
    enum EChanMapType { kOneToOne, kReverse, kGassiplexAdapter1,
			kGassiplexAdapter2, kTable };

    
    EChanMapType  fMapType;     // Type of hardware channel mapping to use
    Vint_t        fChanMap;     // [fNelem] Optional hardware channel mapping
    Int_t         MapChannel( Int_t idx ) const;

    // Parameters, calibration, flags
    UInt_t        fMaxClusterSize;// Maximum size of a clean cluster of strips
    Double_t      fMinAmpl;     // ADC threshold for strips to be active
    Double_t      fSplitFrac;   // Percentage of amplitude swing necessary
                                // for detecting cluster maximum/minimum
    Double_t      fminPeakADC;  // Threshold on peak adc within 2-4 time sample
    Double_t      fPeakTimeMin; // minimum threshold on peak time
    Double_t      fPeakTimeMax; // maximum threshold on peak time
    UInt_t        fMaxSamp;     // Maximum # ADC samples per channel

    Vflt_t        fPed;         // [fNelem] Per-channel pedestal values
    Int_t         fcModeSize;   // Number of strips in same common mode group
    TBits         fBadChan;     // Bad channel map
    Double_t      fAmplSigma;   // Sigma of hit amplitude distribution
    Int_t         fpedestal_sigma;
    Int_t         ftmp_pedestal_rms;
    /* Double_t         fpedestal_sigma; */
    /* Double_t         ftmp_pedestal_rms; */
    Int_t         ftmp_comm_range;



    // Event data, hits etc.
    Float_t*      fADCraw;      // [fNelem] Integral of raw ADC samples
    Float_t*      fADC;         // [fNelem] Integral of deconvoluted ADC samples
    Float_t*      fHitTime;     // [fNelem] Leading-edge time of deconv signal (ns)
    Float_t*      fADCcor;      // [fNelem] fADC corrected for pedestal & noise
    Float_t*      fMCCharge;    // storage for mc charge
    Byte_t*       fGoodHit;     // [fNelem] Strip data passed pulse shape test
    Float_t*      fPrimFrac;    // [fNelem] Strip data passed pulse shape test
    Double_t      fDnoise;      // Event-by-event noise (avg below fMinAmpl)
    Vint_t        fSigStrips;   // Ordered strip numbers with signal (adccor > minampl)
    std::map<Int_t, Int_t> fmStripModule; // Module ID of the strip;
    Vbool_t       fStripsSeen;  // Flags for duplicate strip number detection

    UInt_t        fNrawStrips;  // Statistics: strips with any data
    UInt_t        fNhitStrips;  // Statistics: strips > 0
    Double_t      fHitOcc;      // Statistics: hit occupancy fNhitStrips/fNelem
    Double_t      fOccupancy;   // Statistics: occupancy GetNsigStrips/fNelem
    // pulse fit---temprary need to find better ways
    //Int_t         fMaxPulsePoints = 20;
    //temparary variable for test
    //UInt_t        fTotalPriHit=0,fCoveredPriHit=0;
    UInt_t        fTotalPriHit;
    UInt_t        fCoveredPriHit;

    std::map<Int_t,StripData_t> mStrip; //strips passed zero suppression.
    
    //Variables for fit clustering method:
    Short_t fClusOption;
    // 0: Danning's method (default) 
    // 1: Latif's Method (will probably not implement - EF) 
    // 2: Single Fit Method
    //bool kDoSamples;

    // Thresholds for Clusoption>0
    Int_t fSampThr;
    Int_t fHiSampThr;
    Int_t fCentStripThr;
    Int_t fNshPeakshMin;
    
    Double_t fTimeBin;
    Double_t fSpreadHit;
    Double_t fTimeCst;
    

    //strip/sample ADC data array: 
    std::map<Int_t, std::vector<Int_t> > fADCarray;
    // std::vector< HitCandidate >* Hit_cand_
    // std::vector< HitCandidate >* Hit_cand_prim_

    
    // Optional diagnostics for TESTCODE, keep for binary compatibility
    TH1*          fADCMap;      // Histogram of strip numbers weighted by ADC
    //Histo for clus option 2 control
    TH1*          fSamp;     // Histogram of strip numbers weighted by ADC
    TH1*          fHiSamp;     // Histogram of strip numbers weighted by ADC
    TH1*          fADCcent;     // Histogram of strip numbers weighted by ADC
    
    void          AddStrip( Int_t istrip, Int_t module );

    // Support functions for dummy planes
    virtual Hit*  AddHitImpl( Double_t x );
    virtual Int_t GEMDecode( const THaEvData& );

    void DoClustering();//from mStrip to fhit TODO

    //functions and utilities for fit clustering method
    virtual Int_t DefaultClustering( );
    virtual Int_t ClusteringFitTemplate( );
    
    //utilities for Fit clustering method
    Double_t HitPosTimeFit(int centstrip, int peaksamp, 
			   int& ADCsum, double& amp, double& pos, double& time, 
			   int rangeL, int rangeR = -1);
    Double_t IntegralHitPosFitFunc(double Amp, double Pos, double Time,
				   double x1, double x2);

    
    void ValueCmp(TClonesArray* f);
    virtual Double_t GetModuleOffsets(Int_t module){return 0;};

    // Podd interface
    virtual Int_t ReadDatabase( const TDatime& date );
    virtual Int_t DefineVariables( EMode mode = kDefine );

    // Bits for GEMPlanes
    enum {
      kDoNoise         = BIT(16), // Correct data for common-mode noise
      kCheckPulseShape = BIT(17)  // Reject malformed ADC pulse shapes
    };

    ClassDef(GEMPlane,0)  // ADC-based readout plane coordinate direction
  };

///////////////////////////////////////////////////////////////////////////////

} // end namespace TreeSearch


#endif
