(*Moulinette by Arthur GONTIER 2020 (explenation generator from constraint decomposition)*) 
open List 
type var_name = X | B of int | T | I | V | N  
(*indice options*) 
type ind_name = I of int | T of int 
type ind_set = D of int 
type ind_const = C of int 
type ind_symbols = PLUS|MINUS|IN|NEQ|LEQ|GEQ|EQ 
type ind_modifs = | Set of ind_name*ind_symbols*ind_set (*I∈D*) 
           | Rel of ind_name*ind_symbols*ind_name (*I≠I2*) 
           | Addint of ind_name*ind_name*ind_symbols*int (*I2=I+1*) 
           | Addcst of ind_name*ind_name*ind_symbols*ind_const*ind_name (*I3=I2-C I*) 
           | EXFORALL of ind_name 
           | EXEXISTS of ind_name 
type consistancy = AC | BC 
(*Global indice type*) 
type index = {ind_name:ind_name;ind_modifs_list:ind_modifs list} 
(*variable*) 
type event_var = { var_sign:bool; var_name:var_name;index_list:index list} 
(*variables in ctrs*) 
type decomp_var = {dec_var_sign:bool;dec_var_name:var_name;index_propagate:index list->index list;index_update:index list->index list} 
(*explanation tree*) 
type leaf = Var of event_var | T | F | IM | R | FE 
type tree = | Lit of leaf 
           | EXOR of event_var*tree list 
           | EXAND of event_var*tree list 
(*constraint with id, explanation rule and make_decomp_var list*) 
type decomp_ctr = {id:int;explanation_rule:event_var->decomp_var->decomp_ctr->decomp_ctr list->event_var list->tree;dec_var_list:decomp_var list} 
 
(*fast constructors*) 
let make_event_var b n il = {var_sign=b;var_name=n;index_list=il} 
let make_decomp_var b n f fa = {dec_var_sign=b;dec_var_name=n;index_propagate=f;index_update=fa} 
let make_decomp_ctr id r cvl = {id=id;explanation_rule=r;dec_var_list=cvl} 
let make_index i opl = {ind_name=i;ind_modifs_list=opl} 
 
(*Print explanation in string*) 
let rec printprim n = match n with 1 -> "" | _ ->"'"^printprim (n-1)
let printind_name i = match i with I a -> "i_{"^string_of_int a^"}" | T a -> "t_{"^string_of_int a  ^"}"
let printind_set s = match s with D a -> "D_{"^string_of_int a ^"}"
let printind_const c = match c with C a -> "c_{"^string_of_int a ^"}"
let printind_symbols s = match s with PLUS-> "+"|MINUS->"-"|IN->"∈"|NEQ->"≠"|LEQ->"<="|GEQ->">="|EQ->"=" 
let printind_modifs op= match op with 
  | Set (ind1,sym1,set1) ->printind_name ind1^printind_symbols sym1^printind_set set1 
  | Rel (ind1,sym1,ind2) ->printind_name ind1^printind_symbols sym1^printind_name ind2 
  | Addint (ind1,ind2,sym1,int) ->printind_name ind1^"="^printind_name ind2^printind_symbols sym1^string_of_int int 
  | Addcst (ind1,ind2,sym1,cst1,ind3) ->printind_name ind1^"="^printind_name ind2^printind_symbols sym1^printind_const cst1^printind_name ind3 
  | EXFORALL ind1 ->"∀"^printind_name ind1 
  | EXEXISTS ind1 ->"∃"^printind_name ind1 
let rec printiopl il = match il with []->""|i::tl->printind_modifs i^","^printiopl tl 
let printi i = printind_name i.ind_name^" "^printiopl i.ind_modifs_list 
let printcons c v = match c with AC -> if v.var_sign then "=" else "≠" | BC -> if v.var_sign then "≥" else "<" 
let printevent_var cons v = match v.var_name with 
  | X -> "   X"^printind_name (hd v.index_list).ind_name^(printcons cons v)^(match v.index_list with a::b::_ -> printind_name b.ind_name^" "^printiopl b.ind_modifs_list^printiopl a.ind_modifs_list | _ ->failwith "what?") 
  | B i -> "ERROR B " 
  | T -> "ERROR T " 
  | I -> "   I"^printcons cons v^printi (hd v.index_list) 
  | V -> "   V"^printcons cons v^printi (hd v.index_list) 
  | N -> "   N"^printcons cons v^printi (hd v.index_list) 
let rec printe el cons = match el with []->"" | e::tl -> match e with  
  |F|IM|FE|R -> "? "^printe tl cons 
  | T -> printe tl cons 
  | Var v -> printevent_var cons v^printe tl cons 
(*Print explanation in LaTex*) 
let printsymtex s = match s with PLUS-> "+"|MINUS->"-"|IN->" \\in "|NEQ->" \\neq "|LEQ->" \\leq "|GEQ->" \\geq "|EQ->"=" 
let printioptex op= match op with 
  | Set (ind1,sym1,set1) ->printind_name ind1^printsymtex sym1^printind_set set1 
  | Rel (ind1,sym1,ind2) ->printind_name ind1^printsymtex sym1^printind_name ind2 
  | Addint (ind1,ind2,sym1,int) ->printind_name ind1^"="^printind_name ind2^printsymtex sym1^string_of_int int 
  | Addcst (ind1,ind2,sym1,cst1,ind3) ->printind_name ind1^"="^printind_name ind2^printsymtex sym1^printind_const cst1^"_{"^printind_name ind3^"}" 
  | EXFORALL ind1 ->"~\\forall "^printind_name ind1 
  | EXEXISTS ind1 ->"~\\exists "^printind_name ind1 
let rec printiopltex il = match il with []->""|i::tl->printioptex i^",~"^printiopltex tl 
let printitex i = printind_name i.ind_name^" "^printiopltex i.ind_modifs_list 
let printconstex c v = match c with AC -> if v.var_sign then "=" else " \\neq " | BC -> if v.var_sign then " \\geq " else "<" 
let printvartex cons v = match v.var_name with 
  | X -> "X_{"^printind_name (hd v.index_list).ind_name^"}"^(printconstex cons v)^(match v.index_list with a::b::_ -> printind_name b.ind_name^"~"^printiopltex b.ind_modifs_list^printiopltex a.ind_modifs_list | _ ->failwith "what?") 
  | B i -> "ERROR B " 
  | T -> "ERROR T " 
  | I -> "I"^printconstex cons v^printitex (hd v.index_list) 
  | V -> "V"^printconstex cons v^printitex (hd v.index_list) 
  | N -> "N"^printconstex cons v^printitex (hd v.index_list) 
let rec printetex el cons = match el with []->"" | e::tl -> match e with  
  |F|IM|FE|R -> "? "^printetex tl cons 
  | T -> printetex tl cons 
  | Var v -> printvartex cons v^"~~~"^printetex tl cons 
 
let id  x = x(*identity function*) 
let n   x = if x.var_sign then make_event_var false x.var_name x.index_list else make_event_var true x.var_name x.index_list (*negation of event_var x*) 
(*apply index modification functions on a variable*) 
let ap  v cv cvp = make_event_var cv.dec_var_sign cv.dec_var_name (cv.index_propagate (cvp.index_update v.index_list)) 
(*apply index modification functions with negation*) 
let nap v cv cvp = make_event_var (not cv.dec_var_sign) cv.dec_var_name (cv.index_propagate (cvp.index_update v.index_list)) 
 
(*Utilitary functions*) 
let rec invars v cvl = (* make_event_var v in make_decomp_var list? *) 
  match cvl with [] -> false | cv::tl -> if cv.dec_var_name=v.var_name then true else invars v tl 
let rec vars v cvl = (* vars list with the same name as v*) 
  match cvl with [] -> [] | cv::tl -> if cv.dec_var_name=v.var_name then cv::vars v tl else vars v tl 
let rec ctrs v dec = (* constraint list where v is*) 
  match dec with [] -> [] | c::tl -> if invars v c.dec_var_list then c::ctrs v tl else ctrs v tl 
let rec subl v l = (* make_event_var list without variable v*) 
  match l with [] -> [] | c::tl -> if (v.dec_var_sign=c.dec_var_sign)&&(v.dec_var_name=c.dec_var_name) then subl v tl else c::subl v tl 
let rec subc v l = (* make_decomp_ctr list without constraint v*) 
  match l with [] -> [] | c::tl -> if v.id=c.id then subc v tl else c::subc v tl 
let rec inl v l = (* v in list l? *) 
  match l with [] -> false | c::tl -> if v=c then true else inl v tl 
 
(*find and call rules that explain varriable v*) 
let rec find v dec prec ch =  
  if inl v ch || inl (n v) ch then Lit R else 
  let cl = ctrs v dec in 
  let cl = subc prec cl in 
  if cl = [] then Lit IM else 
  EXOR (v,flatten (map (fun c-> map (fun cv -> c.explanation_rule v cv c dec ch) (vars v c.dec_var_list)) cl)) 
 
and fvr vr v cv dec c ch = (*explanation by refied variable*) 
  if vr.dec_var_name = T then Lit T else EXAND (v,[find (ap v vr cv) dec c (ch@[v])]) 
and fnvr vr v cv dec c ch = (*explanation by negative refied variable*) 
  if vr.dec_var_name = T then Lit F else EXAND (v,[find (nap v vr cv) dec c (ch@[v])]) 
and fvl vl v cv dec c ch = (*explanation by variable list*) 
  map (fun cv2-> find (ap v cv2 cv) dec c (ch@[v])) vl 
and fnvl vl v cv dec c ch = (*explanation by negative variable list*) 
  map (fun cv2-> find (nap v cv2 cv) dec c (ch@[v])) vl 
 
(*Explenation rules*) 
and rule1 v cv c dec ch = (*b<=>Xi=t*) 
  let b = hd c.dec_var_list in 
  let x = hd (tl c.dec_var_list) in 
  if b.dec_var_name = v.var_name  
  then if v.var_sign = cv.dec_var_sign 
    then EXAND (v,[Lit (Var ( ap v x b))]) 
    else EXAND (v,[Lit (Var (nap v x b))]) 
  else Lit FE 
 
and rule3 v cv c dec ch = (*conjonction*) 
  let vr = hd c.dec_var_list in 
  if cv.dec_var_name=vr.dec_var_name then 
    if v.var_sign = cv.dec_var_sign 
    then EXAND (v,fvl (tl c.dec_var_list) v cv dec c ch) 
    else EXOR (v,fnvl (tl c.dec_var_list) v cv dec c ch) 
  else  
    let cvl = if not ((tl (tl c.dec_var_list))=[]) then subl cv (tl c.dec_var_list) else c.dec_var_list in 
    if v.var_sign = cv.dec_var_sign 
    then fvr vr v cv dec c ch 
    else EXAND (v,[fnvr vr v cv dec c ch]@(fvl cvl v cv dec c ch)) 
 
and rule4 v cv c dec ch = (*disjunction*) 
  let vr = hd c.dec_var_list in 
  if cv.dec_var_name=vr.dec_var_name then 
    if v.var_sign = cv.dec_var_sign 
    then EXOR (v,fvl (tl c.dec_var_list) v cv dec c ch) 
    else EXAND (v,fnvl (tl c.dec_var_list) v cv dec c ch) 
  else  
    let cvl = if not ((tl (tl c.dec_var_list))=[]) then subl cv (tl c.dec_var_list) else c.dec_var_list in 
    if v.var_sign = cv.dec_var_sign 
    then EXAND (v,[fvr vr v cv dec c ch]@(fnvl cvl v cv dec c ch)) 
    else fnvr vr v cv dec c ch 
 
and rule5 v cv c dec ch = (*Bool sum<=c*) 
  let vr = hd c.dec_var_list in 
  if cv.dec_var_name=vr.dec_var_name then 
    if cv.dec_var_sign = vr.dec_var_sign 
    then EXAND (v,fnvl (tl c.dec_var_list) v cv dec c ch) 
    else EXAND (v,fvl (tl c.dec_var_list) v cv dec c ch)
  else  
    let cvl =subl cv (tl c.dec_var_list) in 
    if not (cvl=[]) then 
      failwith "sommes multiples pas encore implémentés" 
    else  
      if v.var_sign = cv.dec_var_sign 
      then EXAND (v,[fnvr vr v cv dec c ch]@(fnvl (tl c.dec_var_list) v cv dec c ch)) 
      else EXAND (v,[fvr vr v cv dec c ch]@(fvl (tl c.dec_var_list) v cv dec c ch)) 
 
and rule6 v cv c dec ch = (*Bool sum=>c*) 
  let vr = hd c.dec_var_list in 
  if cv.dec_var_name=vr.dec_var_name then 
    if cv.dec_var_sign = vr.dec_var_sign  
    then EXAND (v,fvl (tl c.dec_var_list) v cv dec c ch) 
    else EXAND (v,fnvl (tl c.dec_var_list) v cv dec c ch)
  else  
    let cvl =subl cv (tl c.dec_var_list) in 
    if not (cvl=[]) then 
      failwith "sommes multiples pas encore implémentés" 
    else  
      if v.var_sign = cv.dec_var_sign 
      then EXAND (v,[fvr vr v cv dec c ch]@(fnvl (tl c.dec_var_list) v cv dec c ch)) 
      else EXAND (v,[fnvr vr v cv dec c ch]@(fvl (tl c.dec_var_list) v cv dec c ch))  
 
and rule7 v cv c dec ch = (*Bool sum=c*) 
  let vr = hd c.dec_var_list in 
  if cv.dec_var_name=vr.dec_var_name then 
    if cv.dec_var_sign = vr.dec_var_sign  
    then  EXAND (v,(fvl (tl c.dec_var_list) v cv dec c ch)@(fnvl (tl c.dec_var_list) v cv dec c ch))(*incohérent?*) 
    else EXOR (v,(fvl (tl c.dec_var_list) v cv dec c ch)@(fnvl (tl c.dec_var_list) v cv dec c ch))(*incohérent?*) 
  else  
    let cvl =subl cv (tl c.dec_var_list) in 
    if not (cvl=[]) then 
      failwith "sommes multiples pas encore implémentés" 
    else  
      if v.var_sign = cv.dec_var_sign 
      then EXAND (v,[fvr vr v cv dec c ch]@(fnvl (tl c.dec_var_list) v cv dec c ch)) 
      else EXAND (v,[fvr vr v cv dec c ch]@(fvl (tl c.dec_var_list) v cv dec c ch)) 

let rec removesame l = (*remove keeps one occurence of each element*)
  match l with []->[]|v::tl->if inl v tl then removesame tl else [v]@(removesame tl) 
let rec imp l = (*detect impossibles literals*) 
  match l with []->false | c::tl -> match c with |F|IM|FE|R -> true | _ -> imp tl 
let rec removeimp ll = (*remove explenation with impossible literals*) 
  match ll with []->[]|l::tl->if imp l || inl l tl then removeimp tl else [removesame l]@(removeimp tl) 
 
let morgan l = (*Concaténation d'un EXAND de EXOR en EXOR de EXAND*) 
  match l with []-> [] | l1::[]-> l1 | l1::tl -> fold_left (fun l1 l2 -> flatten (map (fun x -> map (fun y -> x@y) l1) l2)) l1 tl 

let rec an a = (*analysis of the explanation tree, return explanations*) 
  match a with 
    | Lit x -> [[x]] 
    | EXOR (_,l) -> flatten (map an l) 
    | EXAND (_,l) -> morgan (map an l) 

(*Constructors for index modification functions*) 
let prim i = match i with I a -> I (a+1) | T a -> T (a+1) 
let iprim i = make_index (prim i.ind_name) i.ind_modifs_list 
let addint i sym int = make_index (prim i.ind_name) ([Addint ((prim i.ind_name),i.ind_name,sym,int)]@i.ind_modifs_list) 
let addcst i sym cst i2 = make_index (prim i.ind_name) ([Addcst ((prim i.ind_name),i.ind_name,sym,cst,i2.ind_name)]@i.ind_modifs_list) 
let sum i d = make_index (prim i.ind_name) ([EXFORALL (prim i.ind_name);Set (prim i.ind_name,IN,d);Rel (prim i.ind_name,NEQ,i.ind_name);Set (i.ind_name,IN,d)]@i.ind_modifs_list) 
 
(*Index modification functions*)  
let itmc1i il = match il with i::t::_ -> [i;addcst t MINUS (C 1) i](*cumul*) 
let itpc1i il = match il with i::t::_ -> [i;addcst t PLUS (C 1) i](*cumul*) 
 
let sumid1t il = match il with i::t::_ -> [sum i (D 1);t](*sums*) 
 
let i_out il = match il with i::t::_ -> [t](*elem*) 
let t_out il = match il with i::t::_ -> [i]
let tfor_in il = [hd il;make_index (T 1) [EXFORALL (T 1)]] 
let ifor_in il = [make_index (I 1) [EXFORALL (I 1)];hd il] 
 
let isumtd1 il = match il with i::t::_ -> [i;sum t (D 1)](*roots*) 
let isumtd2 il = match il with i::t::_ -> [i;sum t (D 2)](*roots*) 
 
let sumid2t il = match il with i::t::_ -> [sum i (D 2);t](*alleq2*)  
let id1_in_t il = match il with t::_ -> [make_index (I 1) [Set (I 1,IN,D 1)];t]
let id2_in_t il = match il with t::_ -> [make_index (I 1) [Set (I 1,IN,D 2)];t]

let ip1t il = match il with i::t::_ -> [addint i PLUS 1;t](*incr*) 
let im1t il = match il with i::t::_ -> [addint i MINUS 1;t](*incr*) 

let sumtd2 il = match il with t::_ -> [sum t (D 2)](*nvalue*) 
let sumtd3 il = match il with t::_ -> [sum t (D 3)](*nvalue*) 
let tt10_in il = match il with t::_ -> [t;make_index (T 10) [Set (T 10,IN,D 3)]](*nvalue*) 
let t1_in_t il = match il with t::_ -> [make_index (T 1) [Set (T 1,IN,D 2)];t](*nvalue[EXFORALL (T 1);Set (T 1,IN,D 2)]*) 
let tm1 il = match il with t::_ -> [addint t MINUS 1](*nvalue*) 
let tp1 il = match il with t::_ -> [addint t PLUS 1](*nvalue*) 
let sumtd2tprim_out il = match il with t::tt::_ -> [sum t (D 2)](*nvalue*) 

 
 
 
(*Decompositions*) 
let alleq  = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule3 [make_decomp_var true  (B 2) t_out id1_in_t ;make_decomp_var true  (B 1) sumid1t id]; 
              make_decomp_ctr 2 rule3 [make_decomp_var true  (B 3) t_out id2_in_t ;make_decomp_var false (B 1) sumid2t id]; 
              make_decomp_ctr 4 rule4 [make_decomp_var true   T    id id;make_decomp_var true  (B 2) id id;make_decomp_var true  (B 3) id id]] 
let alldif = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule5 [make_decomp_var true   T    id id;make_decomp_var true  (B 1) sumid1t id]] 
let cumul  = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule3 [make_decomp_var true  (B 2) id id;make_decomp_var false (B 1) id id;make_decomp_var true (B 1) itpc1i itmc1i]; 
              make_decomp_ctr 3 rule5 [make_decomp_var true   T    id id;make_decomp_var true  (B 2) sumid1t id]] 
let gcc    = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule7 [make_decomp_var true   T    id id;make_decomp_var true  (B 1) sumid1t id]] 
let incr   = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 4 rule4 [make_decomp_var true   T    id id;make_decomp_var false (B 1) id id;make_decomp_var true  (B 1) ip1t im1t]] 
let elem   = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule1 [make_decomp_var true  (B 2) id id;make_decomp_var true   I    id id]; 
              make_decomp_ctr 3 rule1 [make_decomp_var true  (B 3) id id;make_decomp_var true   V    id id]; 
              make_decomp_ctr 4 rule4 [make_decomp_var true   T    id id;make_decomp_var false (B 3) i_out ifor_in;make_decomp_var false (B 2) t_out tfor_in;make_decomp_var true  (B 1) id id]; 
              make_decomp_ctr 4 rule4 [make_decomp_var true   T    id id;make_decomp_var true  (B 3) i_out ifor_in;make_decomp_var false (B 2) t_out tfor_in;make_decomp_var false (B 1) id id]] 
let roots  = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule7 [make_decomp_var true   T    id id;make_decomp_var true  (B 1) isumtd1 id]; 
              make_decomp_ctr 2 rule7 [make_decomp_var true   T    id id;make_decomp_var true  (B 1) isumtd2 id]] 
let range  = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule6 [make_decomp_var true   T    id id;make_decomp_var true  (B 1) isumtd1 id]; 
              make_decomp_ctr 2 rule7 [make_decomp_var true   T    id id;make_decomp_var true  (B 1) sumid2t id]]
let nvalue = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule4 [make_decomp_var true  (B 2) i_out id1_in_t;make_decomp_var true  (B 1) sumid1t id]; 
              make_decomp_ctr 3 rule7 [make_decomp_var true  (B 4) t_out tt10_in;make_decomp_var true  (B 2)  sumtd2tprim_out t1_in_t];
              make_decomp_ctr 4 rule1 [make_decomp_var true  (B 4) id id;make_decomp_var true   N    id id]]
              (*make_decomp_ctr 5 rule3 [make_decomp_var true  (B 3) id id;make_decomp_var false (B 4) tp1 tm1;make_decomp_var true (B 4) id id]]*)
let atleastnvalue = [make_decomp_ctr 1 rule1 [make_decomp_var true  (B 1) id id;make_decomp_var true   X    id id]; 
              make_decomp_ctr 2 rule4 [make_decomp_var true  (B 2) i_out id1_in_t;make_decomp_var true  (B 1) sumid1t id]; 
              make_decomp_ctr 3 rule5 [make_decomp_var true  (B 4) t_out tt10_in;make_decomp_var true  (B 2)  sumtd2tprim_out t1_in_t];
              make_decomp_ctr 4 rule1 [make_decomp_var true  (B 4) id id;make_decomp_var true   N    id id]]

(*Tests*) 
let x  = make_event_var true  (B 1) [make_index (I 1) [];make_index (T 1) []] 
let i  = make_event_var true  (B 2) [make_index (I 1) []] 
let v  = make_event_var true  (B 3) [make_index (T 1) []] 
let nn = make_event_var true  (B 4) [make_index (T 1) []] 
let printac l = printe l AC 
let printbc l = printe l BC 
let alleqx   = map printbc (an (find    x  alleq (hd alleq) [])) 
let alleqnx  = map printbc (an (find (n x) alleq (hd alleq) [])) 
let alldifx  = map printac (an (find    x  alldif (hd alldif) [])) 
let alldifnx = map printac (an (find (n x) alldif (hd alldif) [])) 
let cumulx   = map printbc (an (find    x  cumul (hd cumul) [])) 
let cumulnx  = map printbc (an (find (n x) cumul (hd cumul) [])) 
let gccx     = map printac (an (find    x  gcc (hd gcc) [])) 
let gccnx    = map printac (an (find (n x) gcc (hd gcc) [])) 
let incrx    = map printbc (an (find    x  incr (hd incr) [])) 
let incrnx   = map printbc (an (find (n x) incr (hd incr) [])) 
let elemx    = map printac (an (find    x  elem (hd elem) [])) 
let elemnx   = map printac (an (find (n x) elem (hd elem) [])) 
let elemi    = map printac (an (find    i  elem (hd (tl elem)) [])) 
let elemni   = map printac (an (find (n i) elem (hd (tl elem)) [])) 
let elemv    = map printac (an (find    v  elem (hd (tl (tl elem))) [])) 
let elemnv   = map printac (an (find (n v) elem (hd (tl (tl elem))) [])) 
let rootsx   = map printac (an (find    x  roots (hd roots) [])) 
let rootsnx  = map printac (an (find (n x) roots (hd roots) [])) 
let rangex   = map printac (an (find    x  range (hd range) [])) 
let rangenx  = map printac (an (find (n x) range (hd range) [])) 
let nvaluex  = map printac (an (find (  x) nvalue (hd nvalue) []))
let nvaluenx = map printac (an (find (n x) nvalue (hd nvalue) []))
 
 
(*Output in tex file*) 
open Printf 
let rec printfraqtex el x cons fic = match el with  
  | [] -> () 
  | e::tl -> fprintf fic "%s" ("$$\\frac{"^e^"}{"^printvartex BC x^"}$$ ");printfraqtex tl x cons fic 
 
(*Output explanations from a decomposition of a global constraint*) 
let explain x dec cons =  
  let fic = open_out "exp.tex" in 
  let exptex = map (fun l-> printetex l cons ) (removeimp (an (find x dec (match dec with a::b::c::d::_->d) []))) in 
  let _ = printfraqtex exptex (make_event_var x.var_sign N [make_index (T 10) []]) cons fic in 
  close_out fic 
 
let _ = explain (n nn) atleastnvalue AC


 
(*TODO : metre dans un vrais type la varible reifiee et les evenements*) 
 
