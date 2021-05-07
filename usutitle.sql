select gorguid_guid as guid
       ,stvterm_desc||' '||ssbsect_subj_code||'-'||ssbsect_crse_numb||'-'||ssbsect_seq_numb||' XL' as usu_crosslist_title
from ssrxlst a inner join ssbsect on a.ssrxlst_term_code = ssbsect_term_code and a.ssrxlst_crn = ssbsect_crn
     inner join scbcrse c ON ssbsect_subj_code = scbcrse_subj_code
                             AND ssbsect_crse_numb = scbcrse_crse_numb
                             AND scbcrse_eff_term = (SELECT MAX (d.scbcrse_eff_term)
                                                     FROM scbcrse d
                                                     WHERE d.scbcrse_eff_term <= ssbsect_term_code
                                                       AND d.scbcrse_crse_numb = c.scbcrse_crse_numb
                                                       AND d.scbcrse_subj_code = c.scbcrse_subj_code)
     inner join stvterm on a.ssrxlst_term_code = stvterm_code
     inner join gorguid on to_char(a.ssrxlst_xlst_group|| '^' || a.ssrxlst_term_code) = gorguid_domain_key and gorguid_ldm_name = 'section-crosslists'
where a.ssrxlst_crn = (select min(b.ssrxlst_crn) 
                       from ssrxlst b 
                       where a.ssrxlst_term_code = b.ssrxlst_term_code
                         and a.ssrxlst_xlst_group = b.ssrxlst_xlst_group)
  and gorguid_guid in (:GUID_LIST)
;
