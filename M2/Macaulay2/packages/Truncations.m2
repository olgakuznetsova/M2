-- TODO:
--  1. truncationPolyhedron: use SkewCommuting info. DONE
--  2. doc truncationImplemented DONE
--  3. figure out what is the story with poly ring over poly ring, with variables in 
--     the coefficient ring having non-zero degrees
--     (e.g. with Join=>true, false).
--  4. for singly graded (or standard graded?) use original code from, engine:
--     it seems quite a bit faster.
--  5. make sure doc for the internal routine is correct: 
--      calls basis with an obscure undocumented option.
--      and the result is wrong for multi-gradings
--      and the doc for truncate is incorrect.
--  6. This is not need here, I think:
--     heft vector: we are doing WAY TOO MUCH work here.
--     heft vector doesn't need to be inside the cone.
--     perhaps start with simplicial part of the cone

newPackage(
        "Truncations",
        Version => "0.5", 
        Date => "30 Dec 2018",
        Authors => {
            {
                Name => "David Eisenbud", 
                Email => "de@msri.org", 
                HomePage => "http://www.msri.org/~de"},
            {
                Name => "Mike Stillman", 
                Email => "mike@math.cornell.edu", 
                HomePage=>"http://www.math.cornell.edu/~mike"}
            },
        Headline => "truncation of a module",
        PackageImports => {"Polyhedra"},
        DebuggingMode => true
        )

export {
    "truncation",
    "truncationImplemented"
    }

protect Exterior

---------------------------
-- DE's test code ---------
---------------------------
--    "trunc",
--    "truncationPolyhedron",
--    "basisPolyhedron",
--    "Exterior"
-- Note: trunc, trunc0 are DE's oriignal code to supplant the 'truncate' command,
-- which was computing the truncation incorrectly in multi-graded situations.
-- actually: the definition of truncation being used was not the best possible.

-- trunc: unused now.  To be removed.
trunc = method()
trunc(List,Module) := (D,M)->(
    --D can be a list of integers, of length = degreeLength ring M,
    --representing a single multi-degree, or a list of lists of multidegrees.
    --the function returns the submodule of M monomials of degree >=d for some d in D
    --requires that all the components of the degrees of R are all >=0.
    R := ring M;

    --in the easy case of a multiprojective space, don't bother with the aux ring.
    deglist := R_*/degree;
    if all(deglist, d->(sum d == 1 and all(d, i-> i>=0))) then return trunc0(D,M);

    --construct an embedding phi1 of R into a standard graded auxilliary ring:
    n := numgens R;
    dl := degreeLength R;
    --make a new ring T with n*dl variables, one for each (variable,degree component).
    kk := coefficientRing R;
    t := symbol t;
    T := kk[t_(0,0)..t_(n-1,dl-1)];
   --define a map R->T
    e:=0;
    targ := apply(numgens R, i -> (
	e = degree R_i;
	product(dl,j->t_(i,j)^(e_j))
	    ));
    phi1 := map(T,R,targ);

    --now construct the truncation, using the ring map over and over    
    if class D_0 =!= List then (
        L := gens M;
        dM := (degrees (gens M))_1;
        M1 := apply(#dM, i-> 
	    trunc(positivePart(D-dM_i),phi1)*image(L_{i}));
        trim sum M1
        )
    else
        trim sum(D, d->trunc(d,M))
    )

positivePart = method()
positivePart List := L -> apply(L, ell-> max(ell,0))

-- trunc0: unused now.  To be removed.
trunc0 = method()
trunc0(List, Module) := (D,M) ->(
    --A fix for the basic truncate command in the case of a module on multi-projective space.
    --If i is a multi-degree, then the result of truncate(i,M)
    --should be the submodule generated by all elements of degree >= i in the partial order.
    --The script assumes that the degrees of the variables in ring M are the basis vectors,
    --not something more exotic.
    if class D_0 =!= List then (
    dl := degreeLength M;
    L := gens M;
    dM := (degrees (gens M))_1;
    if all(dM, m -> all(dl, i-> m_i<=D_i)) then return image basis(D,M);
    S := ring M;
    M1 := apply(#dM, i-> 
	    ideal(basis(positivePart(D-dM_i),S,Truncate=>true))*image (L_{i}));
    sum M1) else
    trim sum(D, d->trunc0(d,M))
    )

-- trunc: unused.  To be removed.
trunc(List,RingMap) := (d,phi) ->(
    --for the moment we need T to be of the special form greated in trunc(List, Ring):
    --namely, variable t_(i,j) etc.
    --note that t_(i,j) = T_(i+n*j).
    R := source phi;
    n := numgens R;
    dl := degreeLength R;
    T := target phi;
    -- should have n*dl variables t_(i,j), 0<=i<=n-1, and 0<=j<=dl-1 -- that is,
    -- one for each pair (variable, degree component).
    -- now find the ideal in T of elements of degree >= d.
    -- Td := product(dl,j->(ideal(apply(n,i->t_(i,j))))^(d_j));
    Td := product(dl,j->(ideal(apply(n,i->T_(i+n*j))))^(d_j));
    -- the desired ideal is a kernel
    ker(map(T/Td,T)*phi)  -- TODO: this is a monomial map, use normaliz. or oerhaps make kernel faster.
    )

-- trunc: unused.  To be removed.
trunc(List, Ring) := (d,R) ->(
    --produce the ideal in R of all monomials of degree >=D
    --requires that all the components of the degrees of R are all >=0.
    n := numgens R;
    dl := degreeLength R;
    --make a new ring T with n*dl variables, one for each (variable,degree component).
    kk := coefficientRing R;
    t := symbol t;
    skewvarsT := if not R.?SkewCommutative then {} 
                 else (
                    skewvarsR := R.SkewCommutative;
                    flatten for i in skewvarsR list for j from 0 to dl-1 list t_(i,j)
                    );
    T := kk[t_(0,0)..t_(n-1,dl-1), SkewCommutative=>skewvarsT];
      
   --now find the ideal Td in T of elements of degree >= d.
    Td := product(dl,j->(ideal(apply(n,i->t_(i,j))))^(d_j));
   --define a map R->T
    e:=0;
    targ := apply(numgens R, i -> (
	e = degree R_i;
	product(dl,j->t_(i,j)^(e_j))
	    ));
    phi1 := map(T,R,targ);
       --the desired ideal is a kernel of the composite map R --> T/Td.
    U := T ** R;
    Utarg := ideal apply(numgens R, i -> (
	e = degree R_i;
	sub(R_i,U) - sub(product(dl,j->t_(i,j)^(e_j)),U)
        ));
    J := Utarg + sub(Td, U);
    return trim ideal sub(selectInSubring(1, gens gb J), R);
    psi := map(T/Td,T)*phi1;
    psi
    --ker psi
    )

TEST ///
  -- the debug is needed, as trunc is not exported.
  -- once 'trunc' is removed, remove this code too.
  debug needsPackage "Truncations"
  S = ZZ/101[a,b, Degrees =>{{0,1},{1,0}}]
  M = S^{-{5,2}, -{2,3}}
  D = {4,3}
  E = {{4,3},{3,4}}
  assert(trunc(D,S) == ideal(a^3*b^4))
  assert(trunc(D,S^1) == image matrix {{a^3*b^4}})
  assert(trunc(E,S^1) == image matrix {{a^3*b^4, a^4*b^3}})
  assert(trunc(E,M) == image(map(S^{{-5, -2}, {-2, -3}},, {{0, 0, a}, {b^2, a*b, 0}})))
-*
  trunc0(D,S^1)
  trunc0(D,M)
  trunc(D,M)
  trunc0(E,M)
*-
///

------------------------------------------------------------
-- new code that uses Polyhedra to compute lattice points --
------------------------------------------------------------
truncation = method()

truncationPolyhedron = method(Options=>{Exterior => {}})
  -- Exterior should be a list of variable indices which are skew commutative.
  -- i.e. have max degeree 1.
truncationPolyhedron(Matrix, List) := Polyhedron => opts -> (A, b) -> (
    truncationPolyhedron(A, transpose matrix{b}, opts)
    )
truncationPolyhedron(Matrix, Matrix) := Polyhedron => opts -> (A, b) -> (
    -- assumption: A is m x n. b is m x 1.
    -- returns the polyhedron {Ax >= b, x >=0}
    if ring A === ZZ then A = A ** QQ;
    if ring A =!= QQ then error "expected matrix over ZZ or QQ";
    I := id_(source A);
    z := map(source A, QQ^1, 0);
    hdataLHS := -(A || I);
    hdataRHS := -(b || z);
    if #opts.Exterior > 0 then (
        -- also need to add in the conditions that each variable in the list is <= 1.
        ones := matrix toList(#opts.Exterior : {1_QQ});
        hdataLHS = hdataLHS || (I ^ (opts.Exterior));
        hdataRHS = hdataRHS || ones;
        --polyhedronFromHData(-(A || I) || I, -(b || z) || ones)
        );
    polyhedronFromHData(hdataLHS, hdataRHS)
    )

-- basisPolyhedron: this function is not used here.  It can be used for a
-- perhaps better implementation of 'basis'.
-- BUT: it should have exterior variables added too...
basisPolyhedron = method()
basisPolyhedron(Matrix,List) := (A,b) -> (
    basisPolyhedron(A, transpose matrix{b})
    )
basisPolyhedron(Matrix,Matrix) := (A,b) -> (
    -- assumption: A is m x n. b is m x 1.
    -- returns the polyhedron {Ax = b, x >=0}
    if ring A === ZZ then A = A ** QQ;
    if ring A =!= QQ then error "expected matrix over ZZ or QQ";
    I := id_(source A);
    z := map(source A, QQ^1, 0);
    polyhedronFromHData(-I, -z, A, b)
    )

TEST ///
-*
  restart
*-  
  needsPackage "Truncations"
  E = ZZ/101[a..f, SkewCommutative=>{0,2,4}, Degrees=> {2:{3,1},2:{4,-2},2:{1,3}}]
  elapsedTime truncation({7,1},E)

  A = transpose matrix degrees E  
  debug needsPackage "Truncations"  
  elapsedTime numgens truncationMonomials({7,1},E) == 28
  truncate({7,1},E^1) -- this is totally not correct with the new def of truncation.
  
  P = truncationPolyhedron(A,{7,1},Exterior => (options E).SkewCommutative)
  P1 = truncationPolyhedron(A,{7,1})  

  debug needsPackage "Polyhedra"
  elapsedTime halfspaces P
  elapsedTime # hilbertBasis cone P == 1321
  elapsedTime # hilbertBasis cone P1 == 1851
///

-- checkOrMakeDegreeList: takes a degree, and degree rank:ZZ.
-- output: a list of lists of degrees, all of the correct length (degree rank).
--  if it cannot translate the degree(s), an error is issued.
-- in the following list: n represents an integer, and d represents a list of integers.
-- n --> {{n}}  (if degree rank is 1)
-- {n0,...,ns} --> {{n0,...,ns}} (if the length is degree rank).
-- {d0,...,ds} --> {d0,...,ds} (no change, assuming length of each di is the degree rank).
-- an error is provided in any other case.
checkOrMakeDegreeList = method()
checkOrMakeDegreeList(ZZ, ZZ) := (d,degrank) -> (
    if degrank =!= 1 then
        error("expected degree to be of length "|degrank) ;
    {{d}}
    )
checkOrMakeDegreeList(List, ZZ) := (L, degrank) -> (
    if #L === 0 then error "expected non empty list of degrees";
    if all(L, d -> instance(d, ZZ)) then (
        if #L =!= degrank then error("expected a degree of length "|degrank);
        {L}
        )
    else (
        -- all elements of L should be a list of list of integers,
        -- all the same length, and L will be returned.
        if any(L, deg -> not instance(deg, BasicList) 
                         or not all(deg, d -> instance(d,ZZ)) 
                         or #deg =!= degrank)
          then error("expected a list of lists of integers, each of length "|degrank);
        L
        )
    )

-- whether truncation is implemented for this ring type.
truncationImplemented = method()
truncationImplemented Ring := Boolean => R -> (
    (R1, phi1) := flattenRing R;
    A := ambient R1;
    isAffineRing A 
    or
    isPolynomialRing A and isAffineRing coefficientRing A and A.?SkewCommutative
    or
    isPolynomialRing A and ZZ === coefficientRing A
    or
    ZZ === A
    )

TEST ///
-*
  restart
*-
  debug needsPackage "Truncations"
  assert(checkOrMakeDegreeList(3, 1) == {{3}})
  assert(checkOrMakeDegreeList({3}, 1) == {{3}})
  assert try checkOrMakeDegreeList(3, 2) else true 
  assert(checkOrMakeDegreeList({1,2}, 2) === {{1,2}})
  assert try checkOrMakeDegreeList({1,2,3}, 2) else true
  assert(checkOrMakeDegreeList({{1,0},{3,-5}}, 2) === {{1,0},{3,-5}})
  assert try checkOrMakeDegreeList({{1,0},{3,-5},{3,4,5}}, 2) else true
  assert try checkOrMakeDegreeList({{1,0},{3,-5},3}, 2) else true
///

TEST ///
  -- of truncationImplemented
-*
  restart
*-
  debug needsPackage "Truncations"
  R1 = ZZ[a,b,c]
  R2 = R1/(3*a,5*b)
  R3 = R2[s,t] -- current 'truncate' cannot handle this kind of ring.
  R4 = QQ[x,y,z]
  truncationImplemented R1
  truncationImplemented R2
  truncationImplemented R3
  truncationImplemented R4
  
  E1 = ZZ[a,b,c,SkewCommutative=>true]
  E2 = E1/(a*b)
  E3 = ZZ[d,e,f,SkewCommutative=>{0,2}]
  assert((options E3).SkewCommutative == {0,2})
  truncationImplemented E1
  truncationImplemented E2
  truncationImplemented E3
  truncationImplemented (E1[x,y])
  truncationImplemented (E1[x,y,SkewCommutative=>true])
///

truncationMonomials = method()
truncationMonomials(List, Ring) := (degs, R) -> (
    degs = checkOrMakeDegreeList(degs, degreeLength R);
    if #degs > 1 then
        return sum for d in degs list truncationMonomials(d, R);
    d := degs#0;
    if not R#?(symbol truncation, d) then R#(symbol truncation, d) = (
      (R1, phi1) := flattenRing R;
      A := transpose matrix degrees R1;
      P := truncationPolyhedron(A,transpose matrix{d}, Exterior => (options R1).SkewCommutative);
      C := cone P;
      H := hilbertBasis C;
      H = for h in H list flatten entries h;
      J := ideal leadTerm ideal R1;
      ambR := ring J;
      --conegens := rsort for h in H list if h#0 === 0 then ambR_(drop(h,1)) else continue;
      --print matrix {conegens};
      mongens := for h in H list if h#0 === 1 then ambR_(drop(h,1)) else continue;
      result := mingens ideal (matrix(ambR, {mongens}) % J);
      if R1 =!= ambR then result = result ** R1;
      if R =!= R1 then result = phi1^-1 result;
      ideal result
      );
    R#(symbol truncation, d)
    )

TEST ///
-* 
restart
*-
  debug needsPackage "Truncations"
  S = ZZ/101[a,b,c, Degrees =>{5,6,7}]
  truncationMonomials({10}, S)
  assert(truncationMonomials({{9},{11}}, S) == truncationMonomials({9},S))

  E = ZZ/101[a, b, c, SkewCommutative=>true]
  truncationMonomials({2}, E)

  E = ZZ/101[a,b,c, SkewCommutative=>{0,1}]
  truncationMonomials({2}, E) -- FAILS: needs a monomial ideal

  use S
  assert(truncationMonomials({12},S) == ideal"a3,a2b,b2,ac,bc,c2")
  R = S/(a*c-2*b^2)  
  assert(truncationMonomials({12},R) == ideal"a3,a2b,ac,bc,c2")
///

truncation1 = (deg, M) -> (
    -- WARNING: only valid for degree length = 1.
    -- deg: a List of integers
    -- M: Module
    -- returns a submodule of M
    trim if M.?generators then (
        b := M.generators * cover basis(deg,deg,cokernel presentation M,Truncate=>true);
        if M.?relations then subquotient(b, M.relations)
        else image b)
    else image basis(deg,deg,M,Truncate=>true)
    )    

-- truncate the graded ring A in degrees >= d, for d in degs
truncation(List, Ring) := Module => (degs, R) -> (
    if not truncationImplemented R then error "cannot use truncation with this ring type";
    degs = checkOrMakeDegreeList(degs, degreeLength R);
    if degreeLength R === 1 and any(degrees R, d -> d =!= {0}) then
        ideal truncation1(min degs, R^1)
    else 
        ideal gens truncationMonomials(degs,R)
    )

truncation(List, Module) := Module => (degs, M) -> (
    R := ring M;
    if not truncationImplemented R then error "cannot use truncation with this ring type";
    degs = checkOrMakeDegreeList(degs, degreeLength R);
    if degreeLength R === 1 and any(degrees R, d -> d =!= {0}) then
        truncation1(min degs, M)
    else if isFreeModule M then (
        image map(M,,directSum for a in degrees M list 
            gens truncationMonomials(for d in degs list(d-a),R))
        )
    else (
        p := presentation M;
        phi := map(M,,gens truncation(degs, target p));
        trim image phi
        )
    )

truncation(List, Matrix) := Matrix => (degs, phi) -> (
    -- this is the case when source and target of phi are free modules...
    R := ring phi;
    if not truncationImplemented R then error "cannot use truncation with this ring type";
    degs = checkOrMakeDegreeList(degs, degreeLength R);
    F := truncation(degs, source phi);
    G := truncation(degs, target phi);
    f := gens F;
    g := gens G;
    map(G,F,(phi * f) // g)
    )

truncation(List, Ideal) := (degs, I) -> ideal truncation(degs, module I)

truncation(ZZ, Ring) :=
truncation(ZZ, Module) :=
truncation(ZZ, Ideal) :=
truncation(ZZ, Matrix) :=
  (d, R) -> truncation({d}, R)

-- now we switch the 'truncate' command methods to use these
truncate(List, Module) := (degs, M) -> truncation(degs, M)
truncate(List, Ideal) := (degs, I) -> truncation(degs, I)
truncate(List, Ring) := (degs, R) -> truncation(degs, R)

truncate(ZZ, Module) := (deg, M) -> truncation({deg}, M)
truncate(ZZ, Ideal) := (deg, I) -> truncation({deg}, I)
truncate(ZZ, Ring) := (deg, R) -> truncation({deg}, R)

TEST ///
  -- test of truncations in singly graded poly ring case
-*
  -- XXX
  restart
*-
  needsPackage "Truncations"
  
  S = ZZ/101[a..d]
  I = monomialCurveIdeal(S, {1,3,4})
  assert(truncation(2, S) == (ideal vars S)^2)
  assert(truncation(2, S^1) == image gens (ideal vars S)^2)
  elapsedTime truncation(25, S^1);
  elapsedTime truncate(25, S^1); -- (700 times faster)
  -- getting the map from truncation(d,F) --> F
  F = S^{-1} ++ S^{2}
  truncF = truncation(2, F)
  truncF2 = image map(F, truncF, gens truncF)
  truncF === truncF2

  -- test truncation of an ideal
  -- this assumes (tests) that truncation of an ideal is minimally generated.
  truncation(4, I) == truncate(4, I)
  truncI = trim((ideal vars S)^2 * I_0 + (ideal vars S) * ideal(I_1, I_2, I_3))
  assert(truncation(4, I) == truncI)
  ----assert(numgens truncation(4, I) == 18) -- WRONG without trim.
  
  -- test of truncation of modules
  -- 1. coker module
  M = Ext^2(comodule I, S)
  assert not M.?generators
  assert(truncation(-3, M) == M)
  assert(truncation(-4, M) == M)
  truncM = truncation(-2, M)
  assert(truncM == ideal(a,b,c,d) * M)
  -- 2. image module
  -- 3. subquotient module
  C = res I  
  E = trim((ker transpose C.dd_3)/(image transpose C.dd_2))
  truncation(-3, E) == E
  truncation(-4, E) == E
  truncE = truncation(-2, E)
  assert(truncE == ideal(a,b,c,d) * E)
  presentation truncM
  presentation truncE
  
  -- check functoriality:
  assert(0 == truncation(3, C.dd_1) * truncation(3, C.dd_2))
  assert(0 == truncation(3, C.dd_2) * truncation(3, C.dd_3))

  -- how to get the map: truncM == truncation(-2,M) --> M ??
  phi = map(M, truncM, gens truncM)
  assert(image phi == truncM)

  F = truncation(-2, target presentation M)
  G = truncation(-2, source presentation M)
  assert(F == target truncation(-2, presentation M))
  assert(G == source truncation(-2, presentation M))
///

TEST ///
-*
  restart
  needsPackage "Truncations" 
*-
  S = ZZ/101[a,b, Degrees =>{{0,1},{1,0}}]
  M = S^{-{5,2}, -{2,3}}
  D = {4,3}
  assert(truncation(D,S) == image matrix{{a^3*b^4}})
  assert(truncation(D,S) == truncation({D},S))

  E = {{4,3},{3,4}}
  assert(truncation(E,S) == image matrix{{a^3*b^4, a^4*b^3}})

  truncation(D, M)
  truncate(D,M) -- different: is this incorrect? check, but answer is YES!
  
-*
  trunc0(D,S^1)

  trunc0(D,M)
  trunc(D,M)

  trunc0(E,M)
*-
///

TEST ///
-*
  restart
  debug needsPackage "Truncations" 
*-
  S = ZZ/101[a,b,c,d,e,Degrees=>{3,4,5,6,7}]

  assert(
      sort gens truncation({8},S) 
      == 
      sort gens ideal(a*c,b^2,a*d,b*c,a^3,a*e,b*d,c^2,a^2*b,b*e,c*d,c*e,d^2,d*e,e^2)
      )

  truncation({8},S^{-4})
  truncation({8},S^{3})
  truncation({8},S^{-4,-5,-3})
  truncation(8,S^{-4,-5,-3})
  phi = random(S^{-1,-2,-3}, S^{-1,-2,-3,-4,-8})
  psi = truncation({8}, phi)
  assert(isHomogeneous psi)
  
  debug needsPackage "Truncations"   
  assert(sort gens truncation({8},S) == sort gens trunc({8},S^1))
  -- How best to test this??
///


TEST ///
-*
  restart
*-
  debug needsPackage "Truncations" 
  S = ZZ/101[a,b,c,d,e, Degrees=>{3:{1,0},2:{0,1}}]
  assert(sort gens truncation({1,2},S) == sort gens trunc({1,2},S^1))
  assert(sort gens truncation({1,2},S) == sort gens trunc0({1,2},S^1))
///

TEST ///
-*
  restart
  debug needsPackage "Truncations"
*-
  needsPackage "NormalToricVarieties"
  V = smoothFanoToricVariety(3,5)
  rays V
  max V
  S = ring V
  A = transpose matrix degrees S
  truncation({1,1,1}, S)
  basis({1,1,1},S)
  C = posHull A
  C2 = dualCone C
  rays C2
///

TEST ///
  -- test the following:
  --  gradings:
  --    standard grading
  --    ZZ^1 grading
  --    ZZ^r grading
  --  rings:
  --    polynomial ring
  --    exterior algebra
  --    quotient of a poly ring
  --    quotient of an exterior algebra
  --    Weyl algebra (?? probably not: what does this mean)
  --  coeff rings:
  --    a basic field
  --    a poly ring
  --    a quotient of a polynomial ring
  --  truncations:
  --    truncation(D, S)
  --    truncation(D, S^1)
  --    truncation(D, ideal)
  --    truncation(D, graded free module)
  --    truncation(D, coker module)
  --    truncation(D, image module)
  --    truncation(D, subquotient module)
  --    truncation(D, Matrix)
///

TEST ///
-*
  restart
*-
  debug needsPackage "Truncations"
  -- XXX
  d = {5,6}
  D = {d,reverse d}

  kk = ZZ/101
  R = kk[a,b,c,Degrees =>{2:{3,4},{7,5}}]
  truncation({5,6},R)
  truncation({6,5},R)

  J1 = truncation(D, R)
  J1 = truncation(D, R^1)
  truncation(D, ideal(a,b,c))

  A = R/(a^2-b^2, c^3)
  truncation(D, A)
  truncation(d, R)
  M = module ideal(a,b,c)
  truncation(d, ideal(a,b,c))
  truncation(D, ideal(a,b,c))
  p = presentation M
  
  truncation(D, presentation M)
  truncation(D, source presentation M)
  truncation(D, target presentation M)
  

  trunc({5,6},R)
  trunc({5,6},R^1)
  trunc0({5,6},R^1)

  trunc({6,5},R)
  
  elapsedTime J = trunc(d,R)
  M = R^1
  J = trunc(d,R^1)
  J_*/degree
  K = trunc(D,R^1)

///

beginDocumentation()

doc ///
  Key
    Truncations
  Headline
    "truncations of graded ring, ideals and modules"
  Description
    Text
      This package provides for the truncation of a graded ring, or a graded
      module or ideal over a graded ring.
    
      If $R$ is a graded ring, and $M$ is a graded module, and $D$ is a (finite)
      set of degrees, then the truncation {\tt truncation(D, M)} is
      $$M_{\ge D} = \oplus_{m} M_m,$$
      where the sum is over all degree vectors $m \in \ZZ^r$, which are
      component-wise greater than at least one element $d \in D$.
      
      This package handles the multi-graded case correctly, and the
      @TO "truncation"@ function is functorial.
  Caveat
    Not yet reimplemented for all ring cases
  SeeAlso
    truncation
    truncate
    basis
///

doc ///
  Key
    truncationImplemented
    (truncationImplemented, Ring)
  Headline
    whether truncations in the given ring make sense and have been implemented
  Usage
    truncationImplemented R
  Inputs
    R:Ring
  Outputs
    :Boolean
      whether truncations make sense and can be computed for modules over the ring $R$
  Description
    Text
      This function is mostly of use by the package itself, but is sometimes
      useful for programming purposes, so we export this function.

      Currently, truncations of modules can be computed in (commutative or skew commutative) polynomial rings,
      (over a field or the integers),
      quotients thereof, and sometimes in towers of polynomial rings.
      Truncations in the Weyl algebra can be computed via the D-modules package,
      but cannot be constructed using @TO "truncation"@.
    Text
      Truncations can be attempted for polynomial rings:
    Example
      assert truncationImplemented(ZZ/101[a..d])      
      assert truncationImplemented(ZZ/101[a..d, Degrees => {1,1,-1,-1}])
      assert truncationImplemented(ZZ/101[a..d, Degrees => {2:{3,1},2:{-4,2}}])
      
      assert truncationImplemented(QQ[a..d, SkewCommutative=>true])
      assert truncationImplemented(QQ[a..d, SkewCommutative=>{0,3}])

      assert truncationImplemented(ZZ[a..d])      
      assert truncationImplemented(ZZ[a..d, Degrees => {1,1,-1,-1}])
      assert truncationImplemented(ZZ[a..d, Degrees => {2:{3,1},2:{-4,2}}])
      
      assert truncationImplemented(ZZ[a..d, SkewCommutative=>true])
      assert truncationImplemented(ZZ[a..d, SkewCommutative=>{0,3}])
    Text
      Truncations also work for quotients by homogeneous ideals:
    Example
      assert truncationImplemented(ZZ/101[a..d]/(a*d-b*c))
      assert truncationImplemented(ZZ/101[a..d, Degrees => {1,1,-1,-1}]/(a*d-b*c))
      assert truncationImplemented(ZZ/101[a..d, Degrees => {2:{3,1},2:{-4,2}}]/(a*d-b*c))
      
      assert truncationImplemented(QQ[a..d, SkewCommutative=>true]/(a*d-b*c))
      assert truncationImplemented(QQ[a..d, SkewCommutative=>{0,3}]/(a*d-b*c))

      assert truncationImplemented(ZZ[a..d]/(3*a*d-b*c))
      assert truncationImplemented(ZZ[a..d, Degrees => {1,1,-1,-1}]/(a*d-b*c))
      assert truncationImplemented(ZZ[a..d, Degrees => {2:{3,1},2:{-4,2}}]/(a*d-b*c))
      
      assert truncationImplemented(ZZ[a..d, SkewCommutative=>true]/(a*d-b*c))
      assert truncationImplemented(ZZ[a..d, SkewCommutative=>{0,3}]/(a*d-b*c))
  Caveat
    just because this function returns true, doesn't mean that the truncation
    is finitely generated, and will return...
  SeeAlso
    truncation
///

doc ///
  Key
    truncation
    (truncation,ZZ,Module)
    (truncation,List,Module)
    (truncation,ZZ,Ideal)
    (truncation,List,Ideal)
  Headline
    truncation of the graded ring, ideal or module at a specified degree or set of degrees
  Usage
    truncation(d,M)
  Inputs
    d:ZZ
      or a single multi-degree or a list of multi-degrees
    M:Module
      or a ring or an ideal
  Outputs
    :Module
      or ideal, the submodule of M consisting of all elements of degree $\ge i$
  Description
    Text
    Example
      R = ZZ/101[a..c];
      truncation(2,R^1)
      truncation(2,R^1 ++ R^{-3})
      truncation(2, ideal(a,b,c^3)/ideal(a^2,b^2,c^4))
      truncation(2,ideal(a,b*c,c^7))
    Text
      The base may be ZZ, or another polynomial ring.  In this case, the generators may not
      be minimal, but they do generate.
    Example
      A = ZZ[x,y,z];
      truncation(2,ideal(3*x,5*y,15))
      trim oo
      truncation(2,comodule ideal(3*x,5*y,15))
    Text
      If  {\tt i} is a multi-degree, then the result is the submodule generated by all elements
      of degree (component-wise) greater than or equal to $i$.  

      The following example includes the 10 generators needed to
      obtain all graded elements whose degrees which are component-wise 
      at least $\{7,24\}$.
    Example
      S = ZZ/101[x,y,z,Degrees=>{{1,3},{1,4},{1,-1}}];
      trunc = truncation({7,24}, S^1 ++ S^{{-8,-20}})
      degrees trunc      
    Text
      If  {\tt i} is a list of multi-degrees, then the result is the 
      submodule generated by all elements
      of degree (component-wise) greater than or equal to at least one degree in $i$.  

      The following example includes the generators needed to
      obtain all graded elements whose degrees which are component-wise 
      at least $\{3,0\}$ or at least $\{3,0\}$.  Notice that the result is
      not minimally generated.  We use @TO "trim"@ to obtain a module which is minimally
      generated.
    Example
      S = ZZ/101[x,y,z,Degrees=>{{1,3},{1,4},{1,-1}}];
      trunc = truncation({{3,0},{0,1}}, S^1 ++ S^{{-8,-20}})
      trunc = trim trunc
      degrees trunc
    Text
      The coefficient ring may also be a polynomial ring.  In this example, the coefficient variables
      also have degree one.  The given generators will generate the truncation over the coefficient ring.
    Example
      B = R[x,y,z, Join=>false]
      degree x
      degree B_3
      truncation(2, B^1)
      truncation(4, ideal(b^2*y,x^3))
    Text
      If the coefficient variables have degree 0:
    Example
      A1 = ZZ/101[a,b,c,Degrees=>{3:{}}]
      degree a
      B1 = A1[x,y]
      degrees B1
      truncation(2,B1^1)
      truncation(2, ideal(a^3*x, b*y^2))
  Caveat
    The behavior of this function has changed as of Macaulay2 version 1.13.  Before,
    it used a less useful notion of truncation, involving the heft vector,
    and was often not what one wanted in the multi-graded case.
  SeeAlso
    basis
    comodule
///

TEST ///
A = ZZ/101[a..d, Degrees => {1,2,3,4}]
assert(truncation(2, A^1) == image matrix {{a^2, a*b, a*c, a*d, b, c, d}})
assert(truncation(4, ideal"a3,b3") == ideal(a^4,a^3*b,a^3*c,a^3*d,b^3))
///

TEST ///
A = ZZ/101[a..d, Degrees => {4:0}]
assert(truncation(2, A^1) == image matrix{{0_A}})
///

TEST ///
A = ZZ/101[a..d]
truncation(2, ideal"a-1,b3+c")
///

TEST ///
A = ZZ/101[a..d, Degrees=>{2:{1,2},2:{0,1}}]
basis({3}, A^1)


A = ZZ/101[a..d, Degrees=>{2:{2,1},2:{1,0}}]
basis({3}, A^1)


A = ZZ/101[a..d, Degrees=>{2:{2,1,0},2:{1,0,0}}]
basis({3,1}, A^1)
///

TEST ///
R=(ZZ/101)[x_0,x_1,y_0,y_1,y_2,Degrees=>{2:{1,1,0},3:{1,0,1}}];
I=ideal random(R^1,R^{6:{-6,-2,-4},4:{-6,-3,-3}});
J = truncation({4,2,2},I);
assert(J == I)
///

TEST ///
-- Singly generated case
R = QQ[a..d]
I = ideal(b*c-a*d,b^2-a*c,d^10)
truncation(2,I)
truncate(2,I)
assert(truncation(2,I) == I)
assert(truncation(3,I) == intersect((ideal vars R)^3, I))

R = QQ[a..d,Degrees=>{3,4,7,9}]
I = ideal(a^3,b^4,c^6)
assert(truncation(12,I) == ideal(a^4,a^3*b,a^3*c,a^3*d,b^4,c^6))

R = ZZ[a,b,c]
I = ideal(15*a,21*b,19*c)
trim truncation(2,I) == ideal(19*c^2,b*c,a*c,21*b^2,3*a*b,15*a^2)
///

end--
restart
uninstallPackage "Truncations"
restart
loadPackage "Truncations"
debug needsPackage "Truncations"
restart
installPackage "Truncations"
check "Truncations"

doc ///
  Key
  Headline
  Usage
  Inputs
  Outputs
  Description
    Text
    Example
  Caveat
  SeeAlso
///

