NAME = GlovePod

SDKBINPATH ?= /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
SDKVERSION ?= 3.1.2
SYSROOT ?= /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVERSION).sdk

SB_PATH = /Developer/Jailbreak
MS_PATH = /Developer/Jailbreak/MobileSubstrate
LDID = ldid

ARCHS ?= armv6
SDKFLAGS := -isysroot $(SYSROOT) $(foreach ARCH,$(ARCHS),-arch $(ARCH))

CXX = $(SDKBINPATH)/g++-4.2
CXXFLAGS = $(SDKFLAGS) -g0 -O1 -Wall -Werror -include Prefix.pch
LD = $(CXX)
LDFLAGS = -march=armv6 \
		  -mcpu=arm1176jzf-s \
		  -bind_at_load \
		  -multiply_defined suppress \
		  -framework Foundation \
		  -framework UIKit \
		  -F/System/Library/PrivateFrameworks \
		  -framework GraphicsServices \
		  -L$(MS_PATH) -lsubstrate \
		  -lobjc \
		  $(SDKFLAGS)

INCLUDES = -I$(MS_PATH) \
		   -I$(SB_PATH) \
		   -IClasses

SUBDIRS    = . Classes

DIRLIST    := $(SUBDIRS:%=%)
SRCS       := $(foreach dir,$(DIRLIST), $(wildcard $(dir)/*.mm))
HDRS       := $(foreach dir,$(DIRLIST), $(wildcard $(dir)/*.h))
OBJS       := $(SRCS:.mm=.o)

all: $(NAME).dylib

config:
	# Do nothing

clean:
	rm -f $(OBJS) $(NAME).dylib

# Replace 'iphone' with the IP or hostname of your device
install: $(NAME).dylib
	ssh root@iphone rm -f /Library/MobileSubstrate/DynamicLibraries/$(NAME).dylib
	scp $(NAME).dylib root@iphone:/Library/MobileSubstrate/DynamicLibraries/
	ssh root@iphone $(LDID) -S /Library/MobileSubstrate/DynamicLibraries/$(NAME).dylib
	ssh root@iphone restart

release:
	rm -rf release
	cp -a package release
	cp ${NAME}.dylib release/Library/MobileSubstrate/DynamicLibraries/
	find release -iname .svn -exec rm -rf {} \;
	find release -iname .gitignore -exec rm -rf {} \;
	sudo chgrp -R wheel release
	sudo chown -R root release
	sudo dpkg-deb -b release
	sudo mv release.deb ${NAME}.deb
	sudo rm -rf release

$(NAME).dylib: config $(OBJS) $(HDRS)
	$(LD) -dynamiclib $(LDFLAGS) $(OBJS) -o $@

%.o: %.mm
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

.PHONY: all clean
