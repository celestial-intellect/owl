(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)

(** This module contains constants and helper functions used in Owl OpenCL. *)

open Ctypes

open Owl_opencl_generated


(** constant definition *)

let magic_null = Obj.magic null


let uint32_0 = Unsigned.UInt32.zero


let uint32_1 = Unsigned.UInt32.one


let size_0 = Unsigned.Size_t.zero


let size_1 = Unsigned.Size_t.one


let intptr_0 = Intptr.zero


let intptr_1 = Intptr.one


(** coerce from type a to type b *)

let char_ptr_to_uint32_ptr x = coerce (ptr char) (ptr uint32_t) x


let char_ptr_to_size_t_ptr x = coerce (ptr char) (ptr size_t) x


let char_ptr_to_ulong_ptr x = coerce (ptr char) (ptr ulong) x


let char_ptr_to_cl_device_id_ptr x = coerce (ptr char) (ptr cl_device_id) x


let char_ptr_to_cl_platform_id_ptr x = coerce (ptr char) (ptr cl_platform_id) x


let char_ptr_to_cl_context_ptr x = coerce (ptr char) (ptr cl_context) x


let char_ptr_to_cl_program_ptr x = coerce (ptr char) (ptr cl_program) x


let cl_platform_id_to_intptr x =
  let _x = allocate cl_platform_id x in
  let _y = coerce (ptr cl_platform_id) (ptr intptr_t) _x in
  !@_y


let cl_mem_to_void_ptr x =
  let _x = allocate cl_mem x in
  to_voidp _x


let bigarray_to_void_ptr
  : type a b . (a, b, Bigarray.c_layout) Bigarray.Genarray.t -> unit ptr
  = fun x ->
  let open Bigarray in
  let _x = bigarray_start Ctypes_static.Genarray x in
  match Genarray.kind x with
  | Float32 -> coerce (ptr float) (ptr void) _x
  | Float64 -> coerce (ptr double) (ptr void) _x
  | _       -> failwith "owl_opencl_utils:unsupported type"


(** convert between ocaml type and c type *)

let char_ptr_of_string s =
  (* optimise: more efficient way? *)
  let s_len = String.length s in
  let c_ptr = allocate_n char ~count:(s_len + 1) in
  String.iteri (fun j c -> (c_ptr +@ j) <-@ c) s;
  (c_ptr +@ s_len) <-@ '\000';
  c_ptr


let context_properties_to_c_enum properties =
  let n = List.length properties in
  if n = 0 then magic_null
  else (
    let _properties = allocate_n intptr_t ~count:(2 * n + 1) in
    List.iteri (fun i (prop_name, prop_val) ->
      let j = 2 * i in
      (_properties +@ j) <-@ Intptr.of_int prop_name;
      (_properties +@ (j + 1)) <-@ Intptr.of_int prop_val;
    ) properties;
    (_properties +@ (2 * n + 1)) <-@ intptr_0;
    _properties
  )


(* ends here *)
