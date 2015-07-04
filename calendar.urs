(* An extensible calendar: different program modules may contribute different sorts of events *)

(* Generators of calendar entries *)
con t :: {Type}    (* Dictionary of all key fields used across all sources of events *)
         -> {(Type * Type)} (* Mapping user-meaningful tags (for event kinds) to associated data
                             * and the way to encode it imperatively with client-side widgets *)
         -> Type

functor FromTable(M : sig
                      con tag :: Name
                      con key :: {(Type * Type)} (* Each 2nd component is a type of GUI widget private state. *)
                      con when :: Name
                      con other :: {(Type * Type)}
                      con us :: {{Unit}}
                      constraint key ~ other
                      constraint [when] ~ (key ++ other)
                      constraint [When] ~ (key ++ other)
                      val fl : folder key
                      val flO : folder other
                      val inj : $(map (fn p => sql_injectable_prim p.1) key)
                      val injO : $(map (fn p => sql_injectable_prim p.1) other)
                      val ws : $(map Widget.t' (key ++ other))
                      val tab : sql_table (map fst (key ++ other) ++ [when = time]) us
                      val labels : $([when = string] ++ map (fn _ => string) (key ++ other))
                      val eqs : $(map (fn p => eq p.1) key)
                      val title : string
                  end) : sig
    type private
    con tag = M.tag
    con when = M.when
    val cal : t (map fst M.key) [tag = ($([When = time] ++ map fst M.key), private)]
end

val compose : keys1 ::: {Type} -> keys2 ::: {Type}
              -> tags1 ::: {(Type * Type)} -> tags2 ::: {(Type * Type)}
              -> [keys1 ~ keys2] => [tags1 ~ tags2]
              => folder keys1 -> folder keys2
              -> $(map sql_injectable_prim keys1)
              -> $(map sql_injectable_prim keys2)
              -> t keys1 tags1 -> t keys2 tags2 -> t (keys1 ++ keys2) (tags1 ++ tags2)

val items : keys ::: {Type} -> tags ::: {(Type * Type)}
            -> [[When] ~ keys]
            => t keys tags
            -> transaction (list (variant (map fst tags)))

functor Make(M : sig
                 con keys :: {Type}
                 con tags :: {(Type * Type)}
                 constraint [When] ~ keys
                 val t : t keys tags
                 val sh : $(map (fn p => show p.1) tags)
                 val fl : folder tags
             end) : Ui.S where type input = {FromDay : time,
                                             ToDay : time} (* inclusive *)