<TestCase>
  <CaseInfo Description="List Extract" TargetURL="analysisgroup/:AnalysisGroupId/list/extract" Type="BLOCKING" />
  <INPUT ParaName="AnalysisGroupId" SrcValue="xml/add_data_no_vcol/case_00463_add_analysisgroup_brassica.xml" />
  <Match Attr="StatusCode" Value="200" />
  <Match Attr="COUNT" Tag="Extract" TargetDataType="MULTI" Value="boolex(x&gt;0)" />
  <Parent CaseFile="xml/login_testuser/case_00201_login_testuser.xml" Order="1" />
  <Parent CaseFile="xml/login_testuser/case_00203_switch4testu.xml" Force="1" Order="2" />
  <Parent CaseFile="xml/add_data_no_vcol/case_00463_add_analysisgroup_brassica.xml" Order="3" />
  <RunInfo Success="1" Time="1474007226" />
</TestCase>