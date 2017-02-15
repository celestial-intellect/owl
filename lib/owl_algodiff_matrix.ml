(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)

module M = Owl_dense_real

type mat = Owl_dense_real.mat

type t = Float of float | Matrix of mat | Dual of dual
and dual = {
  v : t;       (* primal value *)
  d : t;       (* tangent value *)
}


(* operate on dual numbers *)

let make_dual v d = Dual { v; d }

let value = function
  | Float a -> Float a
  | Matrix a -> Matrix a
  | Dual n -> n.v

let dual = function
  | Float a -> Float 0.
  | Matrix a -> Float 0.
  | Dual n -> n.d

let rec zero = function
  | Float _ -> Float 0.
  | Matrix _ -> Float 0.
  | Dual x -> make_dual (zero x.v) (zero x.d)

let rec one = function
  | Float _ -> Float 1.
  | Dual x -> make_dual (one x.v) (zero x.d)

let is_zero x =
  let rec _is_zero = function
    | Float a -> if a <> 0. then failwith "not zero"
    | Dual x -> (_is_zero x.v; _is_zero x.d)
  in
  try (_is_zero x; true)
  with exn -> false

let is_const x = is_zero (dual x)

let rec sign = function
  | Float a -> Float (if a = 0. then 0. else if a > 0. then 1. else -1.)
  | Dual x -> sign x.v

(* overload operators, module signature *)

module type MathsSig = sig
  val ( +. ) : t -> t -> t
  val ( -. ) : t -> t -> t
  val ( *. ) : t -> t -> t
  val ( /. ) : t -> t -> t
end

module type DerivativeSig = sig

end


(* overload operators, module implementation *)

module rec Maths : MathsSig = struct

  open Derivative

  (* define arithmetic on dual numbers *)

  let rec _add x0 x1 = match x0, x1 with
    | Float x0, Float x1 -> Float Pervasives.(x0 +. x1)
    | Float x0, Dual x1 -> make_dual (_add (Float x0) x1.v) x1.d
    | Dual x0, Float x1 -> make_dual (_add x0.v (Float x1)) x0.d
    | Dual x0, Dual x1 -> make_dual (_add x0.v x1.v) (_add x0.d x1.d)

  let rec _sub x0 x1 = match x0, x1 with
    | Float x0, Float x1 -> Float Pervasives.(x0 -. x1)
    | Float x0, Dual x1 -> make_dual (_sub (Float x0) x1.v) (_sub (Float 0.) x1.d)
    | Dual x0, Float x1 -> make_dual (_sub x0.v (Float x1)) x0.d
    | Dual x0, Dual x1 -> make_dual (_sub x0.v x1.v) (_sub x0.d x1.d)

  let rec _mul x0 x1 = match x0, x1 with
    | Float x0, Float x1 -> Float Pervasives.(x0 *. x1)
    | Float x0, Dual x1 -> make_dual (_mul (Float x0) x1.v) (_mul (Float x0) x1.d)
    | Dual x0, Float x1 -> make_dual (_mul x0.v (Float x1)) (_mul x0.d (Float x1))
    | Dual x0, Dual x1 -> make_dual (_mul x0.v x1.v) (_add (_mul x0.v x1.d) (_mul x0.d x1.v))

  let rec _div x0 x1 = match x0, x1 with
    | Float x0, Float x1 -> Float Pervasives.(x0 /. x1)
    | Float x0, Dual x1 -> let y = _div (Float x0) x1.v in make_dual y (_mul (Float (-1.)) (_mul (_div y x1.v) x1.d))
    | Dual x0, Float x1 -> make_dual (_div x0.v (Float x1)) (_div x0.d (Float x1))
    | Dual x0, Dual x1 -> make_dual (_div x0.v x1.v) (_sub (_div x0.d x1.v) (_div (_mul x0.v x1.d) (_mul x1.v x1.v)))

  let ( +. ) x0 x1 = _add x0 x1

  let ( -. ) x0 x1 = _sub x0 x1

  let ( *. ) x0 x1 = _mul x0 x1

  let ( /. ) x0 x1 = _div x0 x1

end and
Derivative : DerivativeSig = struct

  open Maths


end


(* helper functions and wrappers *)


(* ends here *)