#---Utility Macros----------------------------------------------------------
function(GET_NCPUS ncpu)
  if(APPLE)
    execute_process(COMMAND /usr/sbin/sysctl hw.ncpu 
                    OUTPUT_VARIABLE out RESULT_VARIABLE rc)
    if(NOT rc)
      string(REGEX MATCH "[0-9]+" n ${out})
    endif()
  elseif(UNIX)
    execute_process(COMMAND cat /proc/cpuinfo 
                    OUTPUT_VARIABLE out RESULT_VARIABLE rc)
    if(NOT rc)
      string(REGEX MATCHALL "processor" procs ${out})
      list(LENGTH procs n)
    endif()
  elseif(WIN32)
    set(n $ENV{NUMBER_OF_PROCESSORS})
  endif()
  if(DEFINED n)
    set(${ncpu} ${n} PARENT_SCOPE)
  else()
    set(${ncpu} 1 PARENT_SCOPE)
  endif()
endfunction()

function(GET_CONFIGURATION_TAG tag)
  #---arch--------------
  if(APPLE)
    execute_process(COMMAND uname -m OUTPUT_VARIABLE arch OUTPUT_STRIP_TRAILING_WHITESPACE)
  elseif(UNIX)
    execute_process(COMMAND uname -p OUTPUT_VARIABLE arch OUTPUT_STRIP_TRAILING_WHITESPACE)
  elseif(DEFINED ENV{Platform})
    set(arch $ENV{Platform})
    string(TOLOWER ${arch} arch)
  else()
    set(arch $ENV{PROCESSOR_ARCHITECTURE})
  endif()
  #---os----------------
  if(APPLE)
    set(os mac)
    execute_process(COMMAND sw_vers "-productVersion" 
                    COMMAND cut -d . -f 1-2 
                    OUTPUT_VARIABLE osvers OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REPLACE "." "" osvers ${osvers})
  elseif(WIN32)
    set(os winxp)
    set(osvers)
  else()
    execute_process(COMMAND lsb_release -is OUTPUT_VARIABLE osid OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND lsb_release -rs OUTPUT_VARIABLE osvers OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(osid MATCHES Ubuntu)
      string(REGEX REPLACE "([0-9]+)[.].*" "\\1" osvers "${osvers}")
      set(os ubuntu)
    elseif(osid MATCHES Scientific)
      string(REGEX REPLACE "([0-9]+)[.].*" "\\1" osvers "${osvers}")
      set(os slc)
    elseif(osid MATCHES Fedora)
      string(REGEX REPLACE "([0-9]+)" "\\1" osvers "${osvers}")
      set(os fedora)
    elseif(osid MATCHES CentOS)
      string(REGEX REPLACE "([0-9]+)[.].*" "\\1" osvers "${osvers}")
      set(os centos)
    else()
      set(os linux)
      set(osvers)
    endif()
  endif()
  #---compiler-----------
  if(DEFINED ENV{CC})
    set(compiler_cmd $ENV{CC})
  elseif(WIN32)
    find_program(compiler_cmd cl)
  elseif(APPLE)
    find_program(compiler_cmd clang)
  else()
    find_program(compiler_cmd gcc)
  endif()
  if(compiler_cmd MATCHES cl.exe$)
    set(compiler vc)
    execute_process(COMMAND ${compiler_cmd} ERROR_VARIABLE versioninfo OUTPUT_VARIABLE out)
    string(REGEX REPLACE ".*Version ([0-9]+)[.].*" "\\1" cvers "${versioninfo}")
	math(EXPR cvers "${cvers} - 6")
  elseif(compiler_cmd MATCHES gcc[0-9]*$)
    set(compiler gcc)
    execute_process(COMMAND ${compiler_cmd} -dumpversion OUTPUT_VARIABLE GCC_VERSION)
    string(REGEX MATCHALL "[0-9]+" GCC_VERSION_COMPONENTS ${GCC_VERSION})
    list(GET GCC_VERSION_COMPONENTS 0 GCC_MAJOR)
    list(GET GCC_VERSION_COMPONENTS 1 GCC_MINOR)
    set(cvers ${GCC_MAJOR}${GCC_MINOR})
  elseif(compiler_cmd MATCHES icc$)
    set(compiler icc)
    execute_process(COMMAND ${compiler_cmd} -dumpversion OUTPUT_VARIABLE ICC_VERSION)
    string(REGEX MATCHALL "[0-9]+" ICC_VERSION_COMPONENTS ${ICC_VERSION})
    list(GET ICC_VERSION_COMPONENTS 0 ICC_MAJOR)
    set(cvers ${ICC_MAJOR})
  elseif(compiler_cmd MATCHES clang)
    set(compiler clang)
    execute_process(COMMAND ${compiler_cmd} -v ERROR_VARIABLE CLANG_VERSION)
    string(REGEX REPLACE "^.*[ ]([0-9]+)\\.[0-9].*$" "\\1" CLANG_MAJOR "${CLANG_VERSION}")
    string(REGEX REPLACE "^.*[ ][0-9]+\\.([0-9]).*$" "\\1" CLANG_MINOR "${CLANG_VERSION}")
    set(cvers ${CLANG_MAJOR}${CLANG_MINOR})
  else()
    set(compiler unk)
    set(cvers)
  endif()
  set(${tag} ${arch}-${os}${osvers}-${compiler}${cvers} PARENT_SCOPE)
endfunction()

function(GET_PWD pwd)
  if(WIN32)
    execute_process(COMMAND cmd /c cd OUTPUT_VARIABLE p OUTPUT_STRIP_TRAILING_WHITESPACE)
	string(REPLACE "\\" "/" p ${p})
  else()
    set(p $ENV{PWD})
  endif()
  set(${pwd} ${p} PARENT_SCOPE)  
endfunction()

function(GET_HOST host)
  if(WIN32)
    set(h "$ENV{COMPUTERNAME}.$ENV{USERDNSDOMAIN}")
  else()
    execute_process(COMMAND hostname OUTPUT_VARIABLE h OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
  string(TOLOWER ${h} h)
  set(${host} ${h} PARENT_SCOPE)
endfunction()  

function(GET_DATE date)
  if(WIN32)
		execute_process(COMMAND "cmd" "/C date /T" OUTPUT_VARIABLE tmp OUTPUT_STRIP_TRAILING_WHITESPACE)
	elseif(UNIX)
		execute_process(COMMAND "date" "+%d/%m/%Y" OUTPUT_VARIABLE tmp OUTPUT_STRIP_TRAILING_WHITESPACE)
	endif()
	if(tmp)
    string(REGEX REPLACE "(..)/(..)/(....).*" "\\3\\2\\1" tmp ${tmp})
  else()
		message(STATUS "WARNING: Date Not Implemented")
		set(tmp 0000)
	endiF()
  set(${date} ${tmp} PARENT_SCOPE)
endfunction()

function(GET_TIME time)
  if(WIN32)
		execute_process(COMMAND "cmd" "/C time /T" OUTPUT_VARIABLE tmp OUTPUT_STRIP_TRAILING_WHITESPACE)
	elseif(UNIX)
		execute_process(COMMAND "date" "+%H:%M" OUTPUT_VARIABLE tmp OUTPUT_STRIP_TRAILING_WHITESPACE)
	endif()
	if(tmp)
    string(REGEX REPLACE "(..):(..)*" "\\1\\2" tmp ${tmp})
  else()
		message(STATUS "WARNING: Time Not Implemented")
		set(tmp 0000)
	endiF()
  set(${time} ${tmp} PARENT_SCOPE)
endfunction()

function(WRITE_INGNORED_TESTS file)
  file(WRITE ${file} "Lists of tests ignored for this build:\n")
  foreach(t ${CTEST_CUSTOM_TESTS_IGNORE})
    file(APPEND ${file} "${t}\n")
  endforeach()
endfunction()
