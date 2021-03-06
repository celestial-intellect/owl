(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)

open Ctypes

open Owl_opencl_utils

open Owl_opencl_generated

module CI = Cstubs_internals


(** platform definition *)
module Platform = struct

  type info = {
    profile    : string;
    version    : string;
    name       : string;
    vendor     : string;
    extensions : string;
  }


  let get_platforms () =
    let _n = allocate uint32_t uint32_0 in
    clGetPlatformIDs uint32_0 cl_platform_id_ptr_null _n |> cl_check_err;
    let n = Unsigned.UInt32.to_int !@_n in
    let _platforms = allocate_n cl_platform_id n in
    clGetPlatformIDs !@_n _platforms magic_null |> cl_check_err;
    Array.init n (fun i -> !@(_platforms +@ i))


  let get_platform_info plf_id param_name =
    let param_name = Unsigned.UInt32.of_int param_name in
    let param_value_size_ret = allocate size_t size_0 in
    clGetPlatformInfo plf_id param_name size_0 null param_value_size_ret |> cl_check_err;

    let _param_value_size = Unsigned.Size_t.to_int !@param_value_size_ret in
    let param_value = allocate_n char ~count:_param_value_size |> Obj.magic in
    clGetPlatformInfo plf_id param_name !@param_value_size_ret param_value magic_null |> cl_check_err;
    (* null terminated string, so minus 1 *)
    string_from_ptr param_value (_param_value_size - 1)


  let get_info plf_id = {
    profile    = get_platform_info plf_id cl_PLATFORM_PROFILE;
    version    = get_platform_info plf_id cl_PLATFORM_VERSION;
    name       = get_platform_info plf_id cl_PLATFORM_NAME;
    vendor     = get_platform_info plf_id cl_PLATFORM_VENDOR;
    extensions = get_platform_info plf_id cl_PLATFORM_EXTENSIONS;
  }


  let to_string x =
    let info = get_info x in
    Printf.sprintf "Platform %s\n" info.profile ^
    Printf.sprintf "  name       : %s\n" info.name ^
    Printf.sprintf "  vendor     : %s\n" info.vendor ^
    Printf.sprintf "  version    : %s\n" info.version ^
    Printf.sprintf "  extensions : %s\n" info.extensions

end



(** device definition *)
module Device = struct

  type info = {
    name                  : string;
    profile               : string;
    vendor                : string;
    version               : string;
    driver_version        : string;
    opencl_c_version      : string;
    build_in_kernels      : string;
    typ                   : int;
    address_bits          : int;
    available             : bool;
    compiler_available    : bool;
    linker_available      : bool;
    global_mem_cache_size : int;
    global_mem_size       : int;
    max_clock_frequency   : int;
    max_compute_units     : int;
    max_parameter_size    : int;
    max_samplers          : int;
    reference_count       : int;
    extensions            : string;
    parent_device         : cl_device_id;
    platform              : cl_platform_id;
  }


  let get_devices plf_id =
    let dev_typ = Unsigned.ULong.of_int cl_DEVICE_TYPE_ALL in
    let _num_devices = allocate uint32_t uint32_0 in
    clGetDeviceIDs plf_id dev_typ uint32_0 cl_device_id_ptr_null _num_devices |> cl_check_err;

    let num_devices = Unsigned.UInt32.to_int !@_num_devices in
    let _devices = allocate_n cl_device_id num_devices in
    clGetDeviceIDs plf_id dev_typ !@_num_devices _devices magic_null |> cl_check_err;
    Array.init num_devices (fun i -> !@(_devices +@ i))


  let get_device_info dev_id param_name =
    let param_name = Unsigned.UInt32.of_int param_name in
    let param_value_size_ret = allocate size_t size_0 in
    clGetDeviceInfo dev_id param_name size_0 null param_value_size_ret |> cl_check_err;

    let _param_value_size = Unsigned.Size_t.to_int !@param_value_size_ret in
    let param_value = allocate_n char ~count:_param_value_size |> Obj.magic in
    clGetDeviceInfo dev_id param_name !@param_value_size_ret param_value magic_null |> cl_check_err;
    param_value, _param_value_size


  let get_info dev_id = {
      name                  = ( let p, l = get_device_info dev_id cl_DEVICE_NAME in string_from_ptr p (l - 1) );
      profile               = ( let p, l = get_device_info dev_id cl_DEVICE_PROFILE in string_from_ptr p (l - 1) );
      vendor                = ( let p, l = get_device_info dev_id cl_DEVICE_VENDOR in string_from_ptr p (l - 1) );
      version               = ( let p, l = get_device_info dev_id cl_DEVICE_VERSION in string_from_ptr p (l - 1) );
      driver_version        = ( let p, l = get_device_info dev_id cl_DRIVER_VERSION in string_from_ptr p (l - 1) );
      opencl_c_version      = ( let p, l = get_device_info dev_id cl_DEVICE_OPENCL_C_VERSION in string_from_ptr p (l - 1) );
      build_in_kernels      = ( let p, l = get_device_info dev_id cl_DEVICE_BUILT_IN_KERNELS in string_from_ptr p (l - 1) );
      typ                   = ( let p, l = get_device_info dev_id cl_DEVICE_TYPE in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
      address_bits          = ( let p, l = get_device_info dev_id cl_DEVICE_ADDRESS_BITS in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
      available             = ( let p, l = get_device_info dev_id cl_DEVICE_AVAILABLE in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int |> ( = ) 1);
      compiler_available    = ( let p, l = get_device_info dev_id cl_DEVICE_COMPILER_AVAILABLE in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int |> ( = ) 1);
      linker_available      = ( let p, l = get_device_info dev_id cl_DEVICE_LINKER_AVAILABLE in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int |> ( = ) 1);
      global_mem_cache_size = ( let p, l = get_device_info dev_id cl_DEVICE_GLOBAL_MEM_CACHE_SIZE in !@(char_ptr_to_ulong_ptr p) |> Unsigned.ULong.to_int);
      global_mem_size       = ( let p, l = get_device_info dev_id cl_DEVICE_GLOBAL_MEM_SIZE in !@(char_ptr_to_ulong_ptr p) |> Unsigned.ULong.to_int);
      max_clock_frequency   = ( let p, l = get_device_info dev_id cl_DEVICE_MAX_CLOCK_FREQUENCY in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
      max_compute_units     = ( let p, l = get_device_info dev_id cl_DEVICE_MAX_COMPUTE_UNITS in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
      max_parameter_size    = ( let p, l = get_device_info dev_id cl_DEVICE_MAX_PARAMETER_SIZE in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
      max_samplers          = ( let p, l = get_device_info dev_id cl_DEVICE_MAX_SAMPLERS in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
      reference_count       = ( let p, l = get_device_info dev_id cl_DEVICE_REFERENCE_COUNT in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
      extensions            = ( let p, l = get_device_info dev_id cl_DEVICE_EXTENSIONS in string_from_ptr p (l - 1) );
      parent_device         = ( let p, l = get_device_info dev_id cl_DEVICE_PARENT_DEVICE in !@(char_ptr_to_cl_device_id_ptr p) );
      platform              = ( let p, l = get_device_info dev_id cl_DEVICE_PLATFORM in !@(char_ptr_to_cl_platform_id_ptr p) );
  }


  let to_string x =
    let info = get_info x in
    Printf.sprintf "Device %s\n" info.profile ^
    Printf.sprintf "  name             : %s\n" info.name ^
    Printf.sprintf "  vendor           : %s\n" info.vendor ^
    Printf.sprintf "  version          : %s\n" info.version ^
    Printf.sprintf "  driver_version   : %s\n" info.driver_version ^
    Printf.sprintf "  opencl_c_version : %s\n" info.opencl_c_version ^
    Printf.sprintf "  build_in_kernels : %s\n" info.build_in_kernels ^
    Printf.sprintf "  reference_count  : %i\n" info.reference_count


end



(** context definition *)
module Context = struct

  type info = {
    reference_count : int;
    num_devices     : int;
    devices         : cl_device_id array;
  }


  let get_context_info ctx param_name =
    let param_name = Unsigned.UInt32.of_int param_name in
    let param_value_size_ret = allocate size_t size_0 in
    clGetContextInfo ctx param_name size_0 null param_value_size_ret |> cl_check_err;

    let _param_value_size = Unsigned.Size_t.to_int !@param_value_size_ret in
    let param_value = allocate_n char ~count:_param_value_size |> Obj.magic in
    clGetContextInfo ctx param_name !@param_value_size_ret param_value magic_null |> cl_check_err;
    param_value, _param_value_size


  let get_info ctx =
    let reference_count = ( let p, l = get_context_info ctx cl_CONTEXT_REFERENCE_COUNT in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int ) in
    let num_devices     = ( let p, l = get_context_info ctx cl_CONTEXT_NUM_DEVICES in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int ) in
    let devices         = ( let p, l = get_context_info ctx cl_CONTEXT_DEVICES in let _devices = char_ptr_to_cl_device_id_ptr p in Array.init num_devices (fun i -> !@(_devices +@ i)) ) in
    {
      reference_count;
      num_devices = num_devices;
      devices = devices;
    }


  let retain ctx = clRetainContext ctx |> cl_check_err


  let release ctx = clReleaseContext ctx |> cl_check_err


  let create ?(properties=[]) devices =
    let _properties = context_properties_to_c_enum properties in
    let num_devices = Array.length devices in
    let _devices = allocate_n cl_device_id ~count:num_devices in
    Array.iteri (fun i d -> (_devices +@ i) <-@ d) devices;
    let _num_devices = Unsigned.UInt32.of_int num_devices in
    let err_ret = allocate int32_t 0l in
    let ctx = clCreateContext _properties _num_devices _devices magic_null magic_null err_ret in
    cl_check_err !@err_ret;
    ctx


  let create_from_type ?(properties=[]) device_typ =
    let _properties = context_properties_to_c_enum properties in
    let _device_typ = Unsigned.ULong.of_int device_typ in
    let err_ret = allocate int32_t 0l in
    let ctx = clCreateContextFromType _properties _device_typ magic_null magic_null err_ret in
    cl_check_err !@err_ret;
    ctx


  let to_string x =
    let info = get_info x in
    Printf.sprintf "Context Info\n" ^
    Printf.sprintf "  reference_count : %i\n" info.reference_count ^
    Printf.sprintf "  num_devices     : %i\n" info.num_devices


end



(** kernel definition *)
module Kernel = struct

  type info = {
    function_name : string;
    num_args : int;
    reference_count : int;
    context : cl_context;
    program : cl_program;
  }


  let get_kernel_info kernel param_name =
    let param_name = Unsigned.UInt32.of_int param_name in
    let param_value_size_ret = allocate size_t size_0 in
    clGetKernelInfo kernel param_name size_0 null param_value_size_ret |> cl_check_err;

    let _param_value_size = Unsigned.Size_t.to_int !@param_value_size_ret in
    let param_value = allocate_n char ~count:_param_value_size |> Obj.magic in
    clGetKernelInfo kernel param_name !@param_value_size_ret param_value magic_null |> cl_check_err;
    param_value, _param_value_size


  let get_info kernel = {
    function_name   = ( let p, l = get_kernel_info kernel cl_KERNEL_FUNCTION_NAME in string_from_ptr p (l - 1) );
    num_args        = ( let p, l = get_kernel_info kernel cl_KERNEL_NUM_ARGS in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
    reference_count = ( let p, l = get_kernel_info kernel cl_KERNEL_REFERENCE_COUNT in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
    context         = ( let p, l = get_kernel_info kernel cl_KERNEL_CONTEXT in !@(char_ptr_to_cl_context_ptr p) );
    program         = ( let p, l = get_kernel_info kernel cl_KERNEL_PROGRAM in !@(char_ptr_to_cl_program_ptr p) );
  }


  let create program kernel_name =
    let _kernel_name = char_ptr_of_string kernel_name in
    let err_ret = allocate int32_t 0l in
    let kernel = clCreateKernel program _kernel_name err_ret in
    cl_check_err !@err_ret;
    kernel


  let create_in_program program kernels = ()


  let set_arg kernel arg_idx arg_size arg_val =
    let _arg_idx = Unsigned.UInt32.of_int arg_idx in
    let _arg_size = Unsigned.Size_t.of_int arg_size in
    let _arg_val = Ctypes.to_voidp arg_val in
    clSetKernelArg kernel _arg_idx _arg_size _arg_val |> cl_check_err


  let enqueue_task ?wait_for cmdq kernel =
    (* TODO: support event list *)
    let event = allocate cl_event cl_event_null in
    clEnqueueTask cmdq kernel uint32_0 magic_null event |> cl_check_err;
    !@event


  let enqueue_ndrange ?wait_for ?(global_work_ofs=[]) ?(local_work_size=[]) cmdq kernel work_dim global_work_size =
    (* TODO: support event list *)
    let event = allocate cl_event cl_event_null in
    let _work_dim = Unsigned.UInt32.of_int work_dim in
    let _local_work_size =
      match local_work_size with
      | [] -> magic_null
      | _  -> local_work_size |> List.map Unsigned.Size_t.of_int |> CArray.of_list size_t |> CArray.start
    in
    let _global_work_ofs =
      match global_work_ofs with
      | [] -> magic_null
      | _  -> global_work_ofs |> List.map Unsigned.Size_t.of_int |> CArray.of_list size_t |> CArray.start
    in
    let _global_work_size = global_work_size |> List.map Unsigned.Size_t.of_int |> CArray.of_list size_t |> CArray.start in
    clEnqueueNDRangeKernel cmdq kernel _work_dim _global_work_ofs _global_work_size _local_work_size uint32_0 magic_null event |> cl_check_err;
    !@event


  let retain kernel = clRetainKernel kernel |> cl_check_err


  let release kernel = clReleaseKernel kernel |> cl_check_err


  let to_string x =
    let info = get_info x in
    Printf.sprintf "Kernel Info\n" ^
    Printf.sprintf "  function_name   : %s\n" info.function_name ^
    Printf.sprintf "  num_args        : %i\n" info.num_args ^
    Printf.sprintf "  reference_count : %i\n" info.reference_count


end



(** program definition *)
module Program = struct

  type info = {
    reference_count : int;
    context         : cl_context;
    num_devices     : int;
    devices         : cl_device_id array;
    source          : string;
    binary_sizes    : int array;
    binaries        : CI.voidp array;
    num_kernels     : int;
    kernel_names    : string array;
  }


  let get_program_info program param_name =
    let param_name = Unsigned.UInt32.of_int param_name in
    let param_value_size_ret = allocate size_t size_0 in
    clGetProgramInfo program param_name size_0 null param_value_size_ret |> cl_check_err;

    let _param_value_size = Unsigned.Size_t.to_int !@param_value_size_ret in
    let param_value = allocate_n char ~count:_param_value_size |> Obj.magic in
    clGetProgramInfo program param_name !@param_value_size_ret param_value magic_null |> cl_check_err;
    param_value, _param_value_size


  let get_info program =
  (* FIXME: many information is only available after the program is built, need to check null *)
  let num_devices = ( let p, l = get_program_info program cl_PROGRAM_NUM_DEVICES in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int ) in
  {
    reference_count = ( let p, l = get_program_info program cl_PROGRAM_REFERENCE_COUNT in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
    context         = ( let p, l = get_program_info program cl_PROGRAM_CONTEXT in !@(char_ptr_to_cl_context_ptr p) );
    num_devices     = num_devices;
    devices         = ( let p, l = get_program_info program cl_PROGRAM_DEVICES in let _devices = char_ptr_to_cl_device_id_ptr p in Array.init num_devices (fun i -> !@(_devices +@ i)) );
    source          = ( let p, l = get_program_info program cl_PROGRAM_SOURCE in string_from_ptr p (l - 1) );
    binary_sizes    = [||]; (* TODO: not implemented yet *)
    binaries        = [||]; (* TODO: not implemented yet *)
    num_kernels     = ( let p, l = get_program_info program cl_PROGRAM_NUM_KERNELS in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
    kernel_names    = ( let p, l = get_program_info program cl_PROGRAM_KERNEL_NAMES in (string_from_ptr p (l - 1)) |> Str.split (Str.regexp ";") |> Array.of_list );
  }


  let create_with_source ctx str =
    let str_num = Array.length str in
    let _str = allocate_n (ptr char) ~count:str_num in
    Array.iteri (fun i s ->
      (_str +@ i) <-@ (char_ptr_of_string s);
    ) str;

    let err_ret = allocate int32_t 0l in
    let str_num = Unsigned.UInt32.of_int str_num in
    let program = clCreateProgramWithSource ctx str_num _str magic_null err_ret in
    cl_check_err !@err_ret;
    program


  let create_with_binary = ()


  let build ?(options="") program devices =
    let num_devices = Array.length devices in
    let _devices = allocate_n cl_device_id ~count:num_devices in
    Array.iteri (fun i d -> (_devices +@ i) <-@ d) devices;
    let _num_devices = Unsigned.UInt32.of_int num_devices in
    let _options = char_ptr_of_string options in
    clBuildProgram program _num_devices _devices _options magic_null magic_null |> cl_check_err


  let compile = ()


  let link = ()


  let release program = clReleaseProgram program |> cl_check_err


  let to_string x =
    let info = get_info x in
    Printf.sprintf "Program Info\n" ^
    Printf.sprintf "  num_devices     : %i\n" info.num_devices ^
    Printf.sprintf "  num_kernels     : %i\n" info.num_kernels ^
    Printf.sprintf "  reference_count : %i\n" info.reference_count ^
    Printf.sprintf "  kernel_names    : %s\n" (Array.fold_left (fun a b -> a ^ b ^ " ") "" info.kernel_names)



end



(** event definition *)
module Event = struct

end



(** command queue definition *)
module CommandQueue = struct

  type info = {
    context          : cl_context;
    device           : cl_device_id;
    reference_count  : int;
    queue_properties : Unsigned.ULong.t;
  }


  let get_commandqueue_info cmdq param_name =
    let param_name = Unsigned.UInt32.of_int param_name in
    let param_value_size_ret = allocate size_t size_0 in
    clGetCommandQueueInfo cmdq param_name size_0 null param_value_size_ret |> cl_check_err;

    let _param_value_size = Unsigned.Size_t.to_int !@param_value_size_ret in
    let param_value = allocate_n char ~count:_param_value_size |> Obj.magic in
    clGetCommandQueueInfo cmdq param_name !@param_value_size_ret param_value magic_null |> cl_check_err;
    param_value, _param_value_size


  let get_info cmdq = {
    context          = ( let p, l = get_commandqueue_info cmdq cl_QUEUE_CONTEXT in !@(char_ptr_to_cl_context_ptr p) );
    device           = ( let p, l = get_commandqueue_info cmdq cl_QUEUE_DEVICE in !@(char_ptr_to_cl_device_id_ptr p) );
    reference_count  = ( let p, l = get_commandqueue_info cmdq cl_QUEUE_REFERENCE_COUNT in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
    queue_properties = ( let p, l = get_commandqueue_info cmdq cl_QUEUE_PROPERTIES in !@(char_ptr_to_ulong_ptr p) );
  }


  let create ?(properties=[]) context device =
    let _properties = List.fold_left ( lor ) 0 properties |> Unsigned.ULong.of_int in
    let err_ret = allocate int32_t 0l in
    let cmdq = clCreateCommandQueue context device _properties err_ret in
    cl_check_err !@err_ret;
    cmdq


  let retain cmdq = clRetainCommandQueue cmdq |> cl_check_err


  let release cmdq = clReleaseCommandQueue cmdq |> cl_check_err


  let flush cmdq = clFlush cmdq |> cl_check_err


  let finish cmdq = clFinish cmdq |> cl_check_err


  let to_string x =
    let info = get_info x in
    Printf.sprintf "CommandQueue Info\n" ^
    Printf.sprintf "  reference_count : %i\n" info.reference_count


end



(** buffer definition *)
module Buffer = struct

  type info = {
    typ             : int;
    size            : int;
    reference_count : int;
    (* host_ptr        : CI.voidp; *)
  }


  let get_buffer_info buf param_name =
    let param_name = Unsigned.UInt32.of_int param_name in
    let param_value_size_ret = allocate size_t size_0 in
    clGetMemObjectInfo buf param_name size_0 null param_value_size_ret |> cl_check_err;

    let _param_value_size = Unsigned.Size_t.to_int !@param_value_size_ret in
    let param_value = allocate_n char ~count:_param_value_size |> Obj.magic in
    clGetMemObjectInfo buf param_name !@param_value_size_ret param_value magic_null |> cl_check_err;
    param_value, _param_value_size


  let get_info buf = {
    typ              = ( let p, l = get_buffer_info buf cl_MEM_TYPE in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
    size             = ( let p, l = get_buffer_info buf cl_MEM_SIZE in !@(char_ptr_to_size_t_ptr p) |> Unsigned.Size_t.to_int );
    reference_count  = ( let p, l = get_buffer_info buf cl_MEM_REFERENCE_COUNT in !@(char_ptr_to_uint32_ptr p) |> Unsigned.UInt32.to_int );
  }


  let create ?(flags=[]) ctx x =
    let _flags = List.fold_left ( lor ) 0 flags |> Unsigned.ULong.of_int in
    let size = Bigarray.Genarray.size_in_bytes x |> Unsigned.Size_t.of_int in
    let _x = bigarray_to_void_ptr x in
    let err_ret = allocate int32_t 0l in
    let buf = clCreateBuffer ctx _flags size _x err_ret in
    cl_check_err !@err_ret;
    buf


  let create_sub () = ()


  let enqueue_read ?(blocking=true) cmdq src ofs len dst =
    let blocking = match blocking with
      | true  -> uint32_1
      | false -> uint32_0
    in
    let ofs = Unsigned.Size_t.of_int ofs in
    let len = Unsigned.Size_t.of_int len in
    (* TODO: support event list *)
    clEnqueueReadBuffer cmdq src blocking ofs len dst uint32_0 magic_null magic_null |> cl_check_err


  let enqueue_write  ?(blocking=true) cmdq src ofs len dst =
    let blocking = match blocking with
      | true  -> uint32_1
      | false -> uint32_0
    in
    let ofs = Unsigned.Size_t.of_int ofs in
    let len = Unsigned.Size_t.of_int len in
    (* TODO: support event list *)
    clEnqueueWriteBuffer cmdq src blocking ofs len dst uint32_0 magic_null magic_null |> cl_check_err


  let retain memobj = clRetainMemObject memobj |> cl_check_err


  let release memobj = clReleaseMemObject memobj |> cl_check_err


  let to_string x =
    let info = get_info x in
    Printf.sprintf "Buffer Info\n" ^
    Printf.sprintf "  typ             : %i\n" info.typ ^
    Printf.sprintf "  size            : %i\n" info.size ^
    Printf.sprintf "  reference_count : %i\n" info.reference_count


end



(** image definition *)
module Image = struct

end



(** shared virtual memroy definition, required opencl 2.0 *)
module SVM = struct

end



(* ends here *)
