#------------------------------------------------------------------------------
# Core library

SRC  = Tracker.cxx Plane.cxx Hit.cxx Hitpattern.cxx \
	Projection.cxx Pattern.cxx PatternTree.cxx PatternGenerator.cxx \
	TreeWalk.cxx Node.cxx Road.cxx \
	GEMTracker.cxx GEMPlane.cxx GEMHit.cxx

EXTRAHDR = Helper.h Types.h EProjType.h

CORE = GEM3DTreeSearch
CORELIB  = lib$(CORE).so
COREDICT = $(CORE)Dict

LINKDEF = $(CORE)_LinkDef.h

#------------------------------------------------------------------------------
# GEM library

#GEMSRC  = GEMTracker.cxx GEMPlane.cxx GEMHit.cxx

#GEM  = GEM3DTreeSearch-GEM
#GEMLIB  = lib$(GEM).so
#GEMDICT = $(GEM)Dict

#GEMLINKDEF = $(GEM)_LinkDef.h

#------------------------------------------------------------------------------
# SBS GEM library

SBSSRC  = SBSSpec.cxx SBSGEMTracker.cxx SBSGEMPlane.cxx

SBS  = GEM3DTreeSearch-SBS
SBSLIB  = lib$(SBS).so
SBSDICT = $(SBS)Dict

SBSLINKDEF = $(SBS)_LinkDef.h

#------------------------------------------------------------------------------
# Compile debug version (for gdb)
#export DEBUG = 1
# Compile extra code for printing verbose messages (enabled with fDebug)
export VERBOSE = 1
# Compile extra diagnostic code (extra computations and global variables)
export TESTCODE = 1
# Compile support code for MC input data
export MCDATA = 1

#export I387MATH = 1
export EXTRAWARN = 1

# Architecture to compile for
ARCH          = linux
#ARCH          = solarisCC5

#------------------------------------------------------------------------------
# Directory locations. All we need to know is INCDIRS.
# INCDIRS lists the location(s) of the C++ Analyzer header (.h) files

ifndef ANALYZER
  $(error $$ANALYZER environment variable not defined)
endif

INCDIRS  = $(wildcard $(addprefix $(ANALYZER)/, include src hana_decode hana_scaler))
INCDIRS  +=${LIBSBSGEM}/src
ifdef EVIO_INCDIR
  INCDIRS += ${EVIO_INCDIR}
else ifdef EVIO
  INCDIRS += ${EVIO}/include
endif

#------------------------------------------------------------------------------
# Do not change anything  below here unless you know what you are doing

ifeq ($(strip $(INCDIRS)),)
  $(error No Analyzer header files found. Check $$ANALYZER)
endif

ROOTCFLAGS   := $(shell root-config --cflags)
ROOTLIBS     := $(shell root-config --libs)
ROOTGLIBS    := $(shell root-config --glibs)
ROOTBIN      := $(shell root-config --bindir)
CXX          := $(shell root-config --cxx)
LD           := $(shell root-config --ld)

PKGINCLUDES  = $(addprefix -I, $(INCDIRS) ) -I$(shell pwd)
INCLUDES     = -I$(shell root-config --incdir) $(PKGINCLUDES)

LIBS          = 
GLIBS         = 

ifeq ($(ARCH),linux)
# Linux with gcc (RedHat)
ifdef DEBUG
  CXXFLAGS    =  -g -O0 #-pthread -std=c++11 -m64 -I/home/danning/cernroot/root6/include
  LDFLAGS     =  -g -O0 #-pthread -std=c++11 -m64 -I/home/danning/cernroot/root6/include
  DEFINES     =
else
  CXXFLAGS    =  -O2 -g  #-pthread -std=c++11 -m64 -I/home/danning/cernroot/root6/include
  LDFLAGS     =  -O -g #-pthread -std=c++11 -m64 -I/home/danning/cernroot/root6/include
#  DEFINES     = -DNDEBUG
endif
DEFINES      += -DLINUXVERS -DHAS_SSTREAM
CXXFLAGS     += -Wall -Woverloaded-virtual -fPIC
DICTCXXFLG   :=
ifdef EXTRAWARN
#FIXME: should be configure'd:
CXXVER       := $(shell g++ --version | head -1 | sed 's/.* \([0-9]\)\..*/\1/')
ifeq ($(CXXVER),4)
CXXFLAGS     += -Wextra -Wno-missing-field-initializers
DICTCXXFLG   := -Wno-strict-aliasing 
endif
endif
SOFLAGS       = -std=c++11 -shared
ifdef I387MATH
CXXFLAGS     += -mfpmath=387
else
CXXFLAGS     += -march=core2 -mfpmath=sse
endif
endif

ifeq ($(ARCH),solarisCC5)
# Solaris CC 5.0
ifdef DEBUG
  CXXFLAGS    = -g
  LDFLAGS     = -g
  DEFINES     =
else
  CXXFLAGS    = -O
  LDFLAGS     = -O
  DEFINES     = -DNDEBUG
endif
DEFINES      += -DSUNVERS -DHAS_SSTREAM
CXXFLAGS     += -KPIC
SOFLAGS       = -G
DICTCXXFLG   :=
endif

ifdef VERBOSE
DEFINES      += -DVERBOSE
endif
ifdef TESTCODE
DEFINES      += -DTESTCODE
endif
ifdef MCDATA
DEFINES      += -DMCDATA
endif

CXXFLAGS     += $(DEFINES) $(ROOTCFLAGS) $(ROOTCFLAGS) $(PKGINCLUDES)
LIBS         += $(ROOTLIBS) $(SYSLIBS)
GLIBS        += $(ROOTGLIBS) $(SYSLIBS)

MAKEDEPEND    = g++ -std=c++11

ifndef PKG
PKG           = lib$(CORE)
LOGMSG        = "$(PKG) source files"
else
LOGMSG        = "$(PKG) Software Development Kit"
endif
DISTFILE      = $(PKG).tar

#------------------------------------------------------------------------------
OBJ           = $(SRC:.cxx=.o) $(COREDICT).o
HDR           = $(SRC:.cxx=.h) $(EXTRAHDR)
DEP           = $(SRC:.cxx=.d)

#GOBJ          = $(GEMSRC:.cxx=.o) $(GEMDICT).o
#GHDR          = $(GEMSRC:.cxx=.h)
#GDEP          = $(GEMSRC:.cxx=.d)

SOBJ          = $(SBSSRC:.cxx=.o) $(SBSDICT).o
SHDR          = $(SBSSRC:.cxx=.h)
SDEP          = $(SBSSRC:.cxx=.d)

all:		$(CORELIB) $(SBSLIB) #$(GEMLIB) 

#gem:		$(GEMLIB)

sbs:		$(SBSLIB)

$(CORELIB):	$(OBJ)
		$(LD) $(LDFLAGS) $(SOFLAGS) -o $@ $^
		@echo "$@ done"

#$(GEMLIB):	$(GOBJ) $(CORELIB)
#		$(LD) $(LDFLAGS) $(SOFLAGS) -o $@ $^ $(CORELIB)
#		@echo "$@ done"

$(SBSLIB):	$(SOBJ) $(CORELIB) # $(GEMLIB)
		$(LD) $(LDFLAGS) $(SOFLAGS) -o $@ $^ $(CORELIB) # $(GEMLIB)
		@echo "$@ done"

#dbconvert:	dbconvert.o
#		$(LD) $(LDFLAGS) $(LIBS) -o $@ $^

dbconvert_sbs:	dbconvert_sbs.o
		$(LD) $(LDFLAGS) $(LIBS) -o $@ $^

ifeq ($(ARCH),linux)
$(COREDICT).o:	$(COREDICT).cxx
	$(CXX) $(CXXFLAGS) $(DICTCXXFLG) -o $@ -c $^
#$(GEMDICT).o:	$(GEMDICT).cxx
#	$(CXX) $(CXXFLAGS) $(DICTCXXFLG) -o $@ -c $^
$(SBSDICT).o:	$(SBSDICT).cxx
	$(CXX) $(CXXFLAGS) $(DICTCXXFLG) -o $@ -c $^
endif

$(COREDICT).cxx: $(HDR) $(LINKDEF)
	@echo "Generating dictionary $(COREDICT)..."
	$(ROOTBIN)/rootcint -f $@ -c $(INCLUDES) $(DEFINES) $^

#$(GEMDICT).cxx: $(GHDR) $(GEMLINKDEF)
#	@echo "Generating dictionary $(GEMDICT)..."
#	$(ROOTBIN)/rootcint -f $@ -c $(INCLUDES) $(DEFINES) $^

$(SBSDICT).cxx: $(SHDR) $(SBSLINKDEF)
	@echo "Generating dictionary $(SBSDICT)..."
	$(ROOTBIN)/rootcint -f $@ -c $(INCLUDES) $(DEFINES) $^

install:	all
		$(error Please define install yourself)
# for example:
#		cp $(USERLIB) $(LIBDIR)

clean:
		rm -f *.o *~ $(CORELIB) $(COREDICT).*
#		rm -f $(GEMLIB) $(GEMDICT).*
		rm -f $(SBSLIB) $(SBSDICT).*

realclean:	clean
		rm -f *.d
		rm -f *.pcm

srcdist:
		rm -f $(DISTFILE).gz
		rm -rf $(PKG)
		mkdir $(PKG)
		cp -p $(SRC) $(HDR) $(LINKDEF) db*.dat Makefile $(PKG)
		cp -p $(SBSLINKDEF) $(PKG) # $(GEMLINKDEF)
		cp -p $(GHDR) $(PKG) # $(GEMSRC)
		cp -p $(SBSSRC) $(SHDR) dbconvert_sbs.cxx $(PKG)
		gtar czvf $(DISTFILE).gz --ignore-failed-read \
		 -V $(LOGMSG)" `date -I`" $(PKG)
		rm -rf $(PKG)

develdist:	srcdist
		mkdir $(PKG)
		ln -s ../.git $(PKG)
		cp -p .gitignore $(PKG)
		gunzip -f $(DISTFILE).gz
		gtar rhvf $(DISTFILE) --exclude=*~ $(PKG)
		xz -f $(DISTFILE)
		rm -rf $(PKG)

.PHONY: all clean realclean srcdist

.SUFFIXES:
.SUFFIXES: .c .cc .cpp .cxx .C .o .d

%.o:	%.cxx
	$(CXX) $(CXXFLAGS) -o $@ -c $<

# FIXME: this only works with gcc
%.d:	%.cxx
	@echo Creating dependencies for $<
	@$(SHELL) -ec '$(MAKEDEPEND) -MM $(INCLUDES) -c $< \
		| sed '\''s%^.*\.o%$*\.o%g'\'' \
		| sed '\''s%\($*\)\.o[ :]*%\1.o $@ : %g'\'' > $@; \
		[ -s $@ ] || rm -f $@'

###

-include $(DEP)
#-include $(GDEP)
-include $(SDEP)

