NAME = GlovePod

SDKBINPATH ?= /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
SDKVERSION ?= 3.1.2
SYSROOT ?= /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVERSION).sdk

SB_PATH = /Developer/Jailbreak
MS_PATH = $(SB_PATH)/MobileSubstrate
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

INCLUDES = -I$(SB_PATH) \
		   -I$(MS_PATH) \
		   -IClasses

SUBDIRS    = . Classes

DIRLIST    := $(SUBDIRS:%=%)
SRCS       := $(foreach dir,$(DIRLIST), $(wildcard $(dir)/*.mm))
HDRS       := $(foreach dir,$(DIRLIST), $(wildcard $(dir)/*.h))
OBJS       := $(SRCS:.mm=.o)

clean:
	rm -f $(OBJS) $(NAME).dylib

%.o: %.mm
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(NAME).dylib: $(OBJS) $(HDRS)
	$(LD) -dynamiclib $(LDFLAGS) $(OBJS) -o $@
	ldid -S $@

package: $(NAME).dylib control
	cp -a layout package
	mkdir -p package/DEBIAN
	cp -a control package/DEBIAN
	cp ${NAME}.dylib package/Library/MobileSubstrate/DynamicLibraries/
	find package -iname .svn -exec rm -rf {} \;
	find package -iname .gitignore -exec rm -rf {} \;
	sudo chgrp -R wheel package
	sudo chown -R root package
	sudo dpkg-deb -b package $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
	sudo rm -rf package

install:
	scp -P2222 $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb root@localhost:.
	ssh -p2222 root@localhost dpkg -i $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
	ssh -p2222 root@localhost respring
