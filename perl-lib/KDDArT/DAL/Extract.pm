#$Id: Extract.pm 785 2014-09-02 06:23:12Z puthick $
#$Author: puthick $

# COPYRIGHT AND LICENSE
# 
# Copyright (C) 2014 by Diversity Arrays Technology Pty Ltd
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Author    : Puthick Hok
# Version   : 2.2.5 build 795
# Created   : 02/09/2013

package KDDArT::DAL::Extract;

use strict;
use warnings;

BEGIN {
  use File::Spec;

  my ($volume, $current_dir, $file) = File::Spec->splitpath(__FILE__);

  $main::kddart_base_dir = "${current_dir}../../..";
}

use lib "$main::kddart_base_dir/perl-lib";

use base 'KDDArT::DAL::Transformation';

use KDDArT::DAL::Common;
use KDDArT::DAL::Security;
use CGI::Application::Plugin::Session;
use Log::Log4perl qw(get_logger :levels);
use XML::Checker::Parser;
use Time::HiRes qw( tv_interval gettimeofday );

sub setup {

  my $self = shift;

  CGI::Session->name("KDDArT_DAL_SESSID");

  __PACKAGE__->authen->init_config_parameters();
  __PACKAGE__->authen->check_login_runmodes(':all');
  __PACKAGE__->authen->check_content_type_runmodes(':all');
  __PACKAGE__->authen->check_rand_runmodes('add_plate_gadmin',
                                           'update_plate_gadmin',
                                           'del_plate_gadmin',
                                           'add_extract_gadmin',
                                           'update_extract_gadmin',
                                           'del_extract_gadmin',
                                           'add_analysisgroup_gadmin',
                                           'add_plate_n_extract_gadmin',
      );
  __PACKAGE__->authen->count_session_request_runmodes(':all');
  
  __PACKAGE__->authen->check_signature_runmodes('update_plate_gadmin',
                                                'del_plate_gadmin',
                                                'add_extract_gadmin',
                                                'update_extract_gadmin',
                                                'del_extract_gadmin',
      );
  __PACKAGE__->authen->check_gadmin_runmodes('add_plate_gadmin',
                                             'update_plate_gadmin',
                                             'del_plate_gadmin',
                                             'add_extract_gadmin',
                                             'update_extract_gadmin',
                                             'del_extract_gadmin',
                                             'add_plate_n_extract_gadmin',
                                             'add_plate_gadmin',

      );
  __PACKAGE__->authen->check_sign_upload_runmodes('add_analysisgroup',
                                                  'add_plate_n_extract_gadmin',
                                                  'add_plate_gadmin',
      );

  $self->run_modes(
    'list_plate_advanced'           => 'list_plate_advanced_runmode',
    'add_plate_gadmin'              => 'add_plate_runmode',
    'update_plate_gadmin'           => 'update_plate_runmode',
    'del_plate_gadmin'              => 'del_plate_runmode',
    'get_plate'                     => 'get_plate_runmode',
    'list_extract'                  => 'list_extract_runmode',
    'add_extract_gadmin'            => 'add_extract_runmode',
    'del_extract_gadmin'            => 'del_extract_runmode',
    'update_extract_gadmin'         => 'update_extract_runmode',
    'get_extract'                   => 'get_extract_runmode',
    'add_analysisgroup'             => 'add_analysisgroup_runmode',
    'list_analysisgroup_advanced'   => 'list_analysisgroup_advanced_runmode',
    'get_analysisgroup'             => 'get_analysisgroup_runmode',
    'add_plate_n_extract_gadmin'    => 'add_plate_n_extract_runmode',
    'add_plate_gadmin'              => 'add_plate_runmode',
      );

  my $logger = get_logger();
  Log::Log4perl::MDC->put('client_ip', $ENV{'REMOTE_ADDR'});

  if ( ! $logger->has_appenders() ) {

    my $app = Log::Log4perl::Appender->new(
                               "Log::Log4perl::Appender::Screen",
                               utf8 => undef
        );

    my $layout = Log::Log4perl::Layout::PatternLayout->new("[%d] [%H] [%X{client_ip}] [%p] [%F{1}:%L] [%M] [%m]%n");

    $app->layout($layout);

    $logger->add_appender($app);
  }

  $logger->level($DEBUG);
  $self->{logger} = $logger;

  $self->authen->config(LOGIN_URL => '');
  $self->session_config(
          CGI_SESSION_OPTIONS => [ "driver:File", $self->query, {Directory=>$SESSION_STORAGE_PATH} ],
      );
}

sub list_plate_advanced_runmode {

=pod list_plate_advanced_HELP_START
{
"OperationName" : "List plates",
"Description": "List DNA extract plates. This listing requires pagination information.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 0,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "FILTERING"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Pagination NumOfRecords='1' NumOfPages='1' Page='1' NumPerPage='1' /><RecordMeta TagName='Plate' /><Plate PlateDescription='Plate Testing' OperatorId='0' DateCreated='2014-07-01 13:18:19' PlateName='Plate_8228736' PlateStatus='' StorageId='0' PlateWells='0' UserName='admin' PlateId='1' PlateType='56' update='update/plate/1'><Extract WellCol='1' WellRow='A' ExtractId='2' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='2' WellRow='A' ExtractId='3' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='3' WellRow='A' ExtractId='4' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='6' WellRow='A' ExtractId='5' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='4' WellRow='A' ExtractId='6' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='5' WellRow='A' ExtractId='7' GenotypeId='0' ItemGroupId='1' /></Plate></DATA>",
"SuccessMessageJSON": "{'Pagination' : [{'NumOfRecords' : '1','NumOfPages' : 1,'NumPerPage' : '1','Page' : '1'}],'VCol' : [],'RecordMeta' : [{'TagName' : 'Plate'}],'Plate' : [{'PlateDescription' : 'Plate Testing','Extract' : [{'WellRow' : 'A','WellCol' : '1','ExtractId' : '2','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '2','ExtractId' : '3','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '3','ExtractId' : '4','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '6','ExtractId' : '5','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '4','ExtractId' : '6','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '5','ExtractId' : '7','GenotypeId' : '0','ItemGroupId' : '1'}],'PlateName' : 'Plate_8228736','DateCreated' : '2014-07-01 13:18:19','OperatorId' : '0','StorageId' : '0','PlateStatus' : '','PlateWells' : '0','UserName' : 'admin','PlateId' : '1','update' : 'update/plate/1','PlateType' : '56'}]}",
"ErrorMessageXML": [{"UnexpectedError": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='Unexpected Error.' /></DATA>"}],
"ErrorMessageJSON": [{"UnexpectedError": "{'Error' : [{'Message' : 'Unexpected Error.' }]}"}],
"URLParameter": [{"ParameterName": "nperpage", "Description": "Number of records in a page for pagination"}, {"ParameterName": "num", "Description": "The page number of the pagination"}],
"HTTPParameter": [{"Required": 0, "Name": "Filtering", "Description": "Filtering parameter string consisting of filtering expressions which are separated by ampersand (&) which needs to be encoded if HTTP GET method is used. Each filtering expression is composed of a database filed name, a filtering operator and the filtering value."}, {"Required": 0, "Name": "FieldList", "Description": "Comma separated value of wanted fields."}, {"Required": 0, "Name": "Sorting", "Description": "Comma separated value of SQL sorting phrases."}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self  = shift;
  my $query = $self->query();

  my $data_for_postrun_href = {};

  my $pagination  = 0;
  my $nb_per_page = -1;
  my $page        = -1;

  if ( (defined $self->param('nperpage')) && (defined $self->param('num')) ) {

    $pagination  = 1;
    $nb_per_page = $self->param('nperpage');
    $page        = $self->param('num');
  }

  my $field_list_csv = '';

  if (defined $query->param('FieldList')) {

    $field_list_csv = $query->param('FieldList');
  }

  my $filtering_csv = '';
  
  if (defined $query->param('Filtering')) {

    $filtering_csv = $query->param('Filtering');
  }

  $self->logger->debug("Filtering csv: $filtering_csv");

  my $sorting = '';

  if (defined $query->param('Sorting')) {

    $sorting = $query->param('Sorting');
  }
  
  my $dbh_k = connect_kdb_read();
  my $dbh_m = connect_mdb_read();

  my $field_list = ['plate.*', 'VCol*'];

  my $other_join = '';

  my ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m, $dbh_k,
                                                                         $field_list, 'plate',
                                                                        'PlateId', $other_join);

  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  $sql .= " LIMIT 1";

  my ($sam_plate_err, $sam_plate_msg, $sam_plate_list_aref) = $self->list_plate(0, $sql, []);

  if ($sam_plate_err) {

    $self->logger->debug("List sample plate failed: $sam_plate_msg");
    my $err_msg = 'Unexpected Error.';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my @field_list_all = keys(%{$sam_plate_list_aref->[0]});

  # no field return, it means no record. error prevention
  if (scalar(@field_list_all) == 0) {
    
    push(@field_list_all, '*');
  }

  my $final_field_list = \@field_list_all;

  if (length($field_list_csv) > 0) {

    my ($sel_field_err, $sel_field_msg, $sel_field_list) = parse_selected_field($field_list_csv,
                                                                                $final_field_list,
                                                                                'PlateId');

    if ($sel_field_err) {

      $self->logger->debug("Parse selected field failed: $sel_field_msg");
      my $err_msg = $sel_field_msg;
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }

    $final_field_list = $sel_field_list;
  }

  $other_join = '';

  ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m, $dbh_k, 
                                                                      $final_field_list, 'plate',
                                                                     'PlateId', $other_join);

  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my ($filter_err, $filter_msg, $filter_phrase, $where_arg) = parse_filtering('PlateId',
                                                                              'plate',
                                                                              $filtering_csv,
                                                                              $final_field_list);

  $self->logger->debug("Filter phrase: $filter_phrase");

  if ($filter_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $filter_msg}]};

    return $data_for_postrun_href;
  }

  my $filtering_exp = '';
  if (length($filter_phrase) > 0) {

    $filtering_exp = " WHERE $filter_phrase ";
  }

  my $pagination_aref    = [];
  my $paged_limit_clause = '';
  my $paged_limit_elapsed;

  if ($pagination) {

    my ($int_err, $int_err_msg) = check_integer_value( {'nperpage' => $nb_per_page,
                                                        'num'      => $page
                                                       });

    if ($int_err) {

      $int_err_msg .= ' not integer.';
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $int_err_msg}]};

      return $data_for_postrun_href;
    }

    $self->logger->debug("Filtering expression: $filtering_exp");

    my $paged_limit_start_time = [gettimeofday()];
   
    my ($pg_id_err, $pg_id_msg, $nb_records,
        $nb_pages, $limit_clause, $rcount_time) = get_paged_filter($dbh_m,
                                                                   $nb_per_page,
                                                                   $page,
                                                                   'plate',
                                                                   'PlateId',
                                                                   $filtering_exp,
                                                                   $where_arg
            );

    $paged_limit_elapsed = tv_interval($paged_limit_start_time);

    $self->logger->debug("SQL Row count time: $rcount_time");

    if ($pg_id_err == 1) {
    
      $self->logger->debug($pg_id_msg);
    
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

      return $data_for_postrun_href;
    }

    if ($pg_id_err == 2) {
      
      $page = 0;
    }

    $pagination_aref = [{'NumOfRecords' => $nb_records,
                         'NumOfPages'   => $nb_pages,
                         'Page'         => $page,
                         'NumPerPage'   => $nb_per_page,
                        }];

    $paged_limit_clause = $limit_clause;
  }

  $dbh_k->disconnect();
  $dbh_m->disconnect();

  $sql  =~ s/GROUP BY/ $filtering_exp GROUP BY /;

  my ($sort_err, $sort_msg, $sort_sql) = parse_sorting($sorting, $final_field_list);

  if ($sort_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $sort_msg}]};

    return $data_for_postrun_href;
  }

  if (length($sort_sql) > 0) {

    $sql .= " ORDER BY $sort_sql ";
  }
  else {

    $sql .= ' ORDER BY plate.PlateId DESC';
  }

  $sql .= " $paged_limit_clause ";

  $self->logger->debug("SQL with VCol: $sql");

  my $data_start_time = [gettimeofday()];
  
  # where_arg here in the list function because of the filtering 
  my ($read_plate_err, $read_plate_msg, $plate_data) = $self->list_plate(1,
                                                                         $sql,
                                                                         $where_arg);

  my $data_elapsed = tv_interval($data_start_time);

  if ($read_plate_err) {

    $self->logger->debug($read_plate_msg);
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $data_for_postrun_href->{'Error'} = 0;
  $data_for_postrun_href->{'Data'}  = {'Plate'      => $plate_data,
                                       'VCol'       => $vcol_list,
                                       'Pagination' => $pagination_aref,
                                       'RecordMeta' => [{'TagName' => 'Plate'}],
  };

  return $data_for_postrun_href;
}

sub list_plate {

  my $self              = $_[0];
  my $extra_attr_yes    = $_[1];
  my $sql               = $_[2];
  my $where_para_aref   = $_[3];

  my $err = 0;
  my $msg = '';

  my $data_aref = [];

  my $dbh_m = connect_mdb_read();
  my $dbh_k = connect_kdb_read();

  ($err, $msg, $data_aref) = read_data($dbh_m, $sql, $where_para_aref);

  if ($err) {

    return ($err, $msg, []);
  }

  my $group_id = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();

  my $plate_id_aref = [];
  my $user_id_href  = {};

  my $chk_id_err        = 0;
  my $chk_id_msg        = '';
  my $used_id_href      = {};
  my $not_used_id_href  = {};

  my $user_lookup       = {};
  my $extract_lookup    = {};

  if ($extra_attr_yes) {

    for my $plate_row (@{$data_aref}) {
      
      push(@{$plate_id_aref}, $plate_row->{'PlateId'});

      if (defined $plate_row->{'OperatorId'}) {

        $user_id_href->{$plate_row->{'OperatorId'}} = 1;
      }
    }

    if (scalar(@{$plate_id_aref}) > 0) {

      my $chk_table_aref = [{'TableName' => 'extract', 'FieldName' => 'PlateId'}];

      ($chk_id_err, $chk_id_msg,
       $used_id_href, $not_used_id_href) = id_existence_bulk($dbh_m, $chk_table_aref, $plate_id_aref);

      if ($chk_id_err) {

        $self->logger->debug("Check id existence error: $chk_id_msg");
        $err = 1;
        $msg = $chk_id_msg;

        return ($err, $msg, []);
      }

      my $extract_sql = 'SELECT PlateId, ExtractId, ItemGroupId, GenotypeId,';
      $extract_sql   .= 'WellRow, WellCol ';
      $extract_sql   .= 'FROM extract ';
      $extract_sql   .= 'WHERE PlateId IN (' . join(',', @{$plate_id_aref}) . ')';

      $self->logger->debug("EXTRACT_SQL: $extract_sql");

      my ($extract_err, $extract_msg, $extract_data) = read_data($dbh_m, $extract_sql, []);

      if ($extract_err) {

        return ($extract_err, $extract_msg, []);
      }

      for my $extract_row (@{$extract_data}) {

        my $plate_id = $extract_row->{'PlateId'};

        if (defined $extract_lookup->{$plate_id}) {

          my $extract_aref = $extract_lookup->{$plate_id};
          delete($extract_row->{'PlateId'});
          push(@{$extract_aref}, $extract_row);
          $extract_lookup->{$plate_id} = $extract_aref;
        }
        else {

          delete($extract_row->{'PlateId'});
          $extract_lookup->{$plate_id} = [$extract_row];
        }
      }
    }

    if (scalar(keys(%{$user_id_href})) > 0) {

      my $user_sql = 'SELECT UserId, UserName FROM systemuser ';
      $user_sql   .= 'WHERE UserId IN (' . join(',', keys(%{$user_id_href})) . ')';

      $self->logger->debug("USER_SQL: $user_sql");

      my $user_sth = $dbh_k->prepare($user_sql);
      $user_sth->execute();
      $user_lookup = $user_sth->fetchall_hashref('UserId');
      $user_sth->finish();
    }
  }

  my @extra_attr_plate_data;

  for my $plate_row (@{$data_aref}) {

    my $plate_id    = $plate_row->{'PlateId'};
    my $operator_id = $plate_row->{'OperatorId'};

    if ($extra_attr_yes) {

      $plate_row->{'UserName'} = $user_lookup->{$operator_id}->{'UserName'};

      if (defined $extract_lookup->{$plate_id}) {

        $plate_row->{'Extract'} = $extract_lookup->{$plate_id};
      }

      if ($gadmin_status eq '1') {

        $plate_row->{'update'} = "update/plate/$plate_id";

        if ($not_used_id_href->{$plate_id}) {

          $plate_row->{'delete'} = "delete/plate/$plate_id";
        }
      }
    }
    push(@extra_attr_plate_data, $plate_row);
  }

  $dbh_k->disconnect();
  $dbh_m->disconnect();

  return ($err, $msg, \@extra_attr_plate_data);
}

sub del_plate_runmode {

=pod del_plate_gadmin_HELP_START
{
"OperationName" : "Delete plate",
"Description": "Delete DNA plate for a specified plate id. Plate can be deleted only if not attached to any lower level related record.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 1,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Info Message='Plate (5) has been deleted successfully.' /></DATA>",
"SuccessMessageJSON": "{'Info' : [{'Message' : 'Plate (6) has been deleted successfully.'}]}",
"ErrorMessageXML": [{"IdUsed": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='Plate (1) is used in extract.' /></DATA>"}],
"ErrorMessageJSON": [{"IdUsed": "{'Error' : [{'Message' : 'Plate (1) is used in extract.'}]}"}],
"URLParameter": [{"ParameterName": "id", "Description": "Existing PlateId."}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self       = shift;
  my $plate_id = $self->param('id');

  my $data_for_postrun_href = {};

  my $dbh_m_read = connect_mdb_read();

  my $plate_exist = record_existence($dbh_m_read, 'plate', 'PlateId', $plate_id);

  if (!$plate_exist) {

    my $err_msg = "Plate ($plate_id) not found.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $plate_in_extract = record_existence($dbh_m_read, 'extract', 'PlateId', $plate_id);

  if ($plate_in_extract) {

    my $err_msg = "Plate ($plate_id) is used in extract.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  $dbh_m_read->disconnect();

  my $dbh_m_write = connect_mdb_write();

  my $sql = 'DELETE FROM platefactor WHERE PlateId=?';
  my $sth = $dbh_m_write->prepare($sql);

  $sth->execute($plate_id);

  if ($dbh_m_write->err()) {

    $self->logger->debug("Delete platefactor failed");
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $sth->finish();

  $sql = 'DELETE FROM plate WHERE PlateId=?';
  $sth = $dbh_m_write->prepare($sql);

  $sth->execute($plate_id);

  if ($dbh_m_write->err()) {

    $self->logger->debug("Delete plate failed");
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $sth->finish();

  $dbh_m_write->disconnect();

  my $info_msg_aref = [{'Message' => "Plate ($plate_id) has been deleted successfully."}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info'      => $info_msg_aref};
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub update_plate_runmode {

=pod update_plate_gadmin_HELP_START
{
"OperationName" : "Update plate",
"Description": "Update DNA plate information specified by id.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 1,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"KDDArTModule": "marker",
"KDDArTTable": "plate",
"KDDArTFactorTable": "platefactor",
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Info Message='Plate (3) has been updated successfully.' /></DATA>",
"SuccessMessageJSON": "{'Info' : [{'Message' : 'Plate (3) has been updated successfully.'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error PlateType='PlateType (251) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'PlateType' : 'PlateType (251) not found.'}]}"}],
"URLParameter": [{"ParameterName": "id", "Description": "Existing PlateId."}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self       = shift;
  my $plate_id = $self->param('id');
  my $query      = $self->query();

  my $data_for_postrun_href = {};

  # Generic required static field checking

  my $dbh_read = connect_mdb_read();

  my $skip_field = {'DateCreated' => 1};

  my ($get_scol_err, $get_scol_msg, $scol_data, $pkey_data) = get_static_field($dbh_read, 'plate');

  if ($get_scol_err) {

    $self->logger->debug("Get static field info failed: $get_scol_msg");
    
    my $err_msg = "Unexpected Error.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $required_field_href = {};

  for my $static_field (@{$scol_data}) {

    my $field_name = $static_field->{'Name'};
    
    if ($skip_field->{$field_name}) { next; }

    if ($static_field->{'Required'} == 1) {

      $required_field_href->{$field_name} = $query->param($field_name);
    }
  }

  $dbh_read->disconnect();

  my ($missing_err, $missing_href) = check_missing_href( $required_field_href );

  if ($missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$missing_href]};

    return $data_for_postrun_href;
  }

  # Finish generic required static field checking

  my $dbh_k_read = connect_kdb_read();
  my $dbh_m_read = connect_mdb_read();

  my $plate_exist = record_existence($dbh_m_read, 'plate', 'PlateId', $plate_id);

  if (!$plate_exist) {

    my $err_msg = "Plate ($plate_id) not found.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $PlateName        = $query->param('PlateName');
  my $OperatorId       = $query->param('OperatorId');

  my $PlateType = read_cell_value($dbh_m_read, 'plate', 'PlateType', 'PlateId', $plate_id);

  if (defined($query->param('PlateType'))) {

    if (length($query->param('PlateType')) > 0) {

      $PlateType = $query->param('PlateType');
    }
  }

  if (length($PlateType) == 0) {

    $PlateType = '0';
  }
  
  my $PlateDescription = read_cell_value($dbh_m_read, 'plate', 'PlateDescription', 'PlateId', $plate_id);

  if (defined($query->param('PlateDescription'))) {

    $PlateDescription = $query->param('PlateDescription');
  }

  my $StorageId = read_cell_value($dbh_m_read, 'plate', 'StorageId', 'PlateId', $plate_id);

  if (defined($query->param('StorageId'))) {

    if (length($query->param('StorageId')) > 0) {

      $StorageId = $query->param('StorageId');
    }
  }

  if (length($StorageId) == 0) {

    $StorageId = '0';
  }

  my $PlateWells = read_cell_value($dbh_m_read, 'plate', 'PlateWells', 'PlateId', $plate_id);

  if (defined($query->param('PlateWells'))) {

    $PlateWells = $query->param('PlateWells');
  }

  my $PlateStatus = read_cell_value($dbh_m_read, 'plate', 'PlateStatus', 'PlateId', $plate_id);

  if (defined($query->param('PlateStatus'))) {

    $PlateStatus = $query->param('PlateStatus');
  }

  if (length($PlateWells) > 0) {

    my ($int_err, $int_href) = check_integer_href( {'PlateWells' => $PlateWells} );

    if ($int_err) {

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [$int_href]};
      
      return $data_for_postrun_href;
    }
  }

  my $sql = "SELECT FactorId, CanFactorHaveNull, FactorValueMaxLength ";
  $sql   .= "FROM factor ";
  $sql   .= "WHERE TableNameOfFactor='platefactor'";

  my $vcol_data = $dbh_k_read->selectall_hashref($sql, 'FactorId');

  my $vcol_param_data = {};
  my $vcol_len_info   = {};
  my $vcol_param_data_maxlen = {};
  for my $vcol_id (keys(%{$vcol_data})) {

    my $vcol_param_name = "VCol_${vcol_id}";
    my $vcol_value      = $query->param($vcol_param_name);
    if ($vcol_data->{$vcol_id}->{'CanFactorHaveNull'} != 1) {

      $vcol_param_data->{$vcol_param_name} = $vcol_value;
    }

    $vcol_len_info->{$vcol_param_name} = $vcol_data->{$vcol_id}->{'FactorValueMaxLength'};
    $vcol_param_data_maxlen->{$vcol_param_name} = $vcol_value;
  }

  my ($vcol_missing_err, $vcol_missing_msg) = check_missing_value( $vcol_param_data );

  if ($vcol_missing_err) {

    $vcol_missing_msg = $vcol_missing_msg . ' missing';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $vcol_missing_msg}]};

    return $data_for_postrun_href;
  }

  my ($vcol_maxlen_err, $vcol_maxlen_msg) = check_maxlen($vcol_param_data_maxlen, $vcol_len_info);

  if ($vcol_maxlen_err) {

    $vcol_maxlen_msg = $vcol_maxlen_msg . ' longer than maximum length.';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $vcol_maxlen_msg}]};

    return $data_for_postrun_href;
  }

  if (!record_existence($dbh_k_read, 'systemuser', 'UserId', $OperatorId)) {

    my $err_msg = "OperatorId ($OperatorId) not found.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
    return $data_for_postrun_href;
  }

  if ($PlateType ne '0') {

    if (!type_existence($dbh_k_read, 'plate', $PlateType)) {

      my $err_msg = "PlateType ($PlateType) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateType' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  if ($StorageId ne '0') {

    if ( !record_existence($dbh_k_read, 'storage', 'StorageId', $StorageId) ) {

      my $err_msg = "StorageId ($StorageId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  my $plate_sql = 'SELECT PlateId FROM plate WHERE PlateId <> ? AND PlateName=?';

  my ($read_plate_err, $exist_plate_id) = read_cell($dbh_m_read, $plate_sql, [$plate_id, $PlateName]);

  if (length($exist_plate_id) > 0) {

    my $err_msg = "($PlateName) already exists.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateName' => $err_msg}]};

    return $data_for_postrun_href;
  }

  $dbh_k_read->disconnect();
  $dbh_m_read->disconnect();

  my $dbh_m_write = connect_mdb_write();

  $sql  = 'UPDATE plate SET ';
  $sql .= 'PlateName=?, ';
  $sql .= 'OperatorId=?, ';
  $sql .= 'PlateType=?, ';
  $sql .= 'PlateDescription=?, ';
  $sql .= 'StorageId=?, ';
  $sql .= 'PlateWells=?, ';
  $sql .= 'PlateStatus=? ';
  $sql .= 'WHERE PlateId=?';

  my $sth = $dbh_m_write->prepare($sql);
  $sth->execute($PlateName, $OperatorId, $PlateType,
                $PlateDescription, $StorageId, $PlateWells, $PlateStatus, $plate_id);

  if ($dbh_m_write->err()) {

    $self->logger->debug("Update plate failed");
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }
  $sth->finish();

  for my $vcol_id (keys(%{$vcol_data})) {

    my $factor_value = $query->param('VCol_' . "$vcol_id");

    $sql  = 'SELECT Count(*) ';
    $sql .= 'FROM platefactor ';
    $sql .= 'WHERE PlateId=? AND FactorId=?';

    my ($read_err, $count) = read_cell($dbh_m_write, $sql, [$plate_id, $vcol_id]);

    if (length($factor_value) > 0) {

      if ($count > 0) {

        $sql  = 'UPDATE platefactor SET ';
        $sql .= 'FactorValue=? ';
        $sql .= 'WHERE PlateId=? AND FactorId=?';
      
        my $factor_sth = $dbh_m_write->prepare($sql);
        $factor_sth->execute($factor_value, $plate_id, $vcol_id);
      
        if ($dbh_m_write->err()) {
        
          $self->logger->debug("Update platefactor failed");
          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

          return $data_for_postrun_href;
        }
    
        $factor_sth->finish();
      }
      else {

        $sql  = 'INSERT INTO platefactor SET ';
        $sql .= 'PlateId=?, ';
        $sql .= 'FactorId=?, ';
        $sql .= 'FactorValue=?';
      
        my $factor_sth = $dbh_m_write->prepare($sql);
        $factor_sth->execute($plate_id, $vcol_id, $factor_value);
      
        if ($dbh_m_write->err()) {
        
          $self->logger->debug("Insert into platefactor failed");
          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

          return $data_for_postrun_href;
        }
    
        $factor_sth->finish();
      }
    }
    else {

      if ($count > 0) {

        $sql  = 'DELETE FROM platefactor ';
        $sql .= 'WHERE PlateId=? AND FactorId=?';

        my $factor_sth = $dbh_m_write->prepare($sql);
        $factor_sth->execute($plate_id, $vcol_id);
      
        if ($dbh_m_write->err()) {
        
          $self->logger->debug("Delete platefactor failed");
          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

          return $data_for_postrun_href;
        }
        $factor_sth->finish();
      }
    }
  }

  $dbh_m_write->disconnect();

  my $info_msg_aref = [{'Message' => "Plate ($plate_id) has been updated successfully."}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info'      => $info_msg_aref};
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub get_plate_runmode {

=pod get_plate_HELP_START
{
"OperationName" : "Get plate",
"Description": "Get detailed information about the DNA plate specified by id.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 0,
"AccessibleHTTPMethod": [{"MethodName": "POST"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><RecordMeta TagName='Plate' /><Plate PlateDescription='Plate Testing' OperatorId='0' DateCreated='2014-07-01 13:18:19' PlateName='Plate_8228736' PlateStatus='' StorageId='0' PlateWells='0' UserName='admin' PlateId='1' PlateType='56' update='update/plate/1'><Extract WellCol='1' WellRow='A' ExtractId='2' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='2' WellRow='A' ExtractId='3' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='3' WellRow='A' ExtractId='4' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='6' WellRow='A' ExtractId='5' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='4' WellRow='A' ExtractId='6' GenotypeId='0' ItemGroupId='1' /><Extract WellCol='5' WellRow='A' ExtractId='7' GenotypeId='0' ItemGroupId='1' /></Plate></DATA>",
"SuccessMessageJSON": "{'VCol' : [],'RecordMeta' : [{'TagName' : 'Plate'}],'Plate' : [{'PlateDescription' : 'Plate Testing','Extract' : [{'WellRow' : 'A','WellCol' : '1','ExtractId' : '2','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '2','ExtractId' : '3','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '3','ExtractId' : '4','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '6','ExtractId' : '5','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '4','ExtractId' : '6','GenotypeId' : '0','ItemGroupId' : '1'},{'WellRow' : 'A','WellCol' : '5','ExtractId' : '7','GenotypeId' : '0','ItemGroupId' : '1'}],'PlateName' : 'Plate_8228736','DateCreated' : '2014-07-01 13:18:19','OperatorId' : '0','StorageId' : '0','PlateStatus' : '','PlateWells' : '0','UserName' : 'admin','PlateId' : '1','update' : 'update/plate/1','PlateType' : '56'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='Plate (6) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'Message' : 'Plate (6) not found.'}]}"}],
"URLParameter": [{"ParameterName": "id", "Description": "Existing PlateId"}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self       = shift;
  my $plate_id = $self->param('id');

  my $data_for_postrun_href = {};

  my $dbh_m = connect_mdb_read();
  my $plate_exist = record_existence($dbh_m, 'plate', 'PlateId', $plate_id);
  $dbh_m->disconnect();

  if (!$plate_exist) {

    my $err_msg = "Plate ($plate_id) not found.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $dbh_k = connect_kdb_read();
  $dbh_m    = connect_mdb_read();

  my $field_list = ['*'];

  my $other_join = '';

  my ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m, $dbh_k,
                                                                         $field_list, 'plate',
                                                                        'PlateId', $other_join);

  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $where_clause = " WHERE plate.PlateId=? ";
  $sql =~ s/GROUP BY/ $where_clause GROUP BY /;

  my ($plate_err, $plate_msg, $plate_list_aref) = $self->list_plate(1, $sql, [$plate_id]);

  if ($plate_err) {

    $self->logger->debug("List plate failed: $plate_msg");
    my $err_msg = 'Unexpected Error.';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  $data_for_postrun_href->{'Error'} = 0;
  $data_for_postrun_href->{'Data'}  = {'Plate'      => $plate_list_aref,
                                       'VCol'       => $vcol_list,
                                       'RecordMeta' => [{'TagName' => 'Plate'}],
  };

  return $data_for_postrun_href;
}

sub logger {

  my $self = shift;
  return $self->{logger};
}

sub list_extract {

  my $self              = $_[0];
  my $extra_attr_yes    = $_[1];
  my $sql               = $_[2];
  my $where_para_aref   = $_[3];

  my $err = 0;
  my $msg = '';

  my $data_aref = [];

  my $dbh_m = connect_mdb_read();
  my $dbh_k = connect_kdb_read();

  ($err, $msg, $data_aref) = read_data($dbh_m, $sql, $where_para_aref);

  if ($err) {

    return ($err, $msg, []);
  }

  my $group_id = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();

  my $extract_id_aref = [];
  my $itm_grp_id_href = {};
  my $geno_id_href    = {};

  my $chk_id_err        = 0;
  my $chk_id_msg        = '';
  my $used_id_href      = {};
  my $not_used_id_href  = {};

  my $analysisgroup_lookup = {};
  my $item_group_lookup    = {};
  my $genotype_lookup      = {};

  if ($extra_attr_yes) {

    for my $extract_row (@{$data_aref}) {

      push(@{$extract_id_aref}, $extract_row->{'ExtractId'});

      if (defined $extract_row->{'ItemGroupId'}) {

        $itm_grp_id_href->{$extract_row->{'ItemGroupId'}} = 1;
      }

      if (defined $extract_row->{'GenotypeId'}) {

        $geno_id_href->{$extract_row->{'GenotypeId'}} = 1;
      }
    }

    if (scalar(@{$extract_id_aref}) > 0) {

      my $chk_table_aref = [{'TableName' => 'analgroupextract', 'FieldName' => 'ExtractId'}];

      ($chk_id_err, $chk_id_msg,
       $used_id_href, $not_used_id_href) = id_existence_bulk($dbh_m, $chk_table_aref, $extract_id_aref);

      if ($chk_id_err) {

        $self->logger->debug("Check id existence error: $chk_id_msg");
        $err = 1;
        $msg = $chk_id_msg;
        
        return ($err, $msg, []);
      }

      my $perm_str = permission_phrase($group_id, 0, 'analysisgroup');

      my $analysis_grp_sql = 'SELECT analgroupextract.ExtractId, analysisgroup.AnalysisGroupId, ';
      $analysis_grp_sql   .= 'analysisgroup.AnalysisGroupName ';
      $analysis_grp_sql   .= 'FROM analysisgroup LEFT JOIN analgroupextract ON ';
      $analysis_grp_sql   .= 'analysisgroup.AnalysisGroupId = analgroupextract.AnalysisGroupId ';
      $analysis_grp_sql   .= 'WHERE analgroupextract.ExtractId IN (' . join(',', @{$extract_id_aref}) . ') ';
      $analysis_grp_sql   .= " AND ((($perm_str) & $READ_PERM) = $READ_PERM)";

      $self->logger->debug("AnalysisGroup permission SQL: $analysis_grp_sql");

      my ($analysis_grp_err, $analysis_grp_msg, $analysis_grp_data) = read_data($dbh_m, $analysis_grp_sql, []);

      if ($analysis_grp_err) {

        return ($analysis_grp_err, $analysis_grp_msg, []);
      }

      for my $anal_grp_row (@{$analysis_grp_data}) {

        my $extract_id = $anal_grp_row->{'ExtractId'};

        if (defined $analysisgroup_lookup->{$extract_id}) {

          my $anal_grp_aref = $analysisgroup_lookup->{$extract_id};
          delete($anal_grp_row->{'ExtractId'});
          push(@{$anal_grp_aref}, $anal_grp_row);
          $analysisgroup_lookup->{$extract_id} = $anal_grp_aref;
        }
        else {

          delete($anal_grp_row->{'ExtractId'});
          $analysisgroup_lookup->{$extract_id} = [$anal_grp_row];
        }
      }
    }

    if (scalar(keys(%{$itm_grp_id_href})) > 0) {

      my $itm_grp_sql = 'SELECT ItemGroupId, ItemGroupName ';
      $itm_grp_sql   .= 'FROM itemgroup WHERE ItemGroupId IN (' . join(',', keys(%{$itm_grp_id_href})) . ')';

      $self->logger->debug("ITM_GRP_SQL: $itm_grp_sql");

      my $itm_grp_sth = $dbh_k->prepare($itm_grp_sql);
      $itm_grp_sth->execute();
      $item_group_lookup = $itm_grp_sth->fetchall_hashref('ItemGroupId');
      $itm_grp_sth->finish();

      $self->logger->debug("ITEM_GROUP_LOOKUP KEY: " . join(',', keys(%{$item_group_lookup})));
    }

    if (scalar(keys(%{$geno_id_href})) > 0) {

      my $geno_sql = 'SELECT GenotypeId, GenotypeName ';
      $geno_sql   .= 'FROM genotype WHERE GenotypeId IN (' . join(',', keys(%{$geno_id_href})) . ')';

      $self->logger->debug("GENO_SQL: $geno_sql");

      my $geno_sth = $dbh_k->prepare($geno_sql);
      $geno_sth->execute();
      $genotype_lookup = $geno_sth->fetchall_hashref('GenotypeId');
      $geno_sth->finish();
    }
  }

  my @extra_attr_extract_data;

  for my $extract_row (@{$data_aref}) {

    my $extract_id    = $extract_row->{'ExtractId'};
    my $item_group_id = $extract_row->{'ItemGroupId'};
    my $genotype_id   = $extract_row->{'GenotypeId'};

    if ($extra_attr_yes) {

      if (defined $item_group_lookup->{$item_group_id}) {

        $extract_row->{'ItemGroupName'} = $item_group_lookup->{$item_group_id}->{'ItemGroupName'};
      }

      if ("$genotype_id" ne '0') {

        if (defined $genotype_lookup->{$genotype_id}) {

          $extract_row->{'GenotypeName'} = $genotype_lookup->{$genotype_id}->{'GenotypeName'};
        }
      }

      if (defined $analysisgroup_lookup->{$extract_id}) {

        $extract_row->{'AnalysisGroup'} = $analysisgroup_lookup->{$extract_id};
      }

      if ($gadmin_status eq '1') {

        $extract_row->{'update'}      = "update/extract/$extract_id";

        if ( $not_used_id_href->{$extract_id} ) {

          $extract_row->{'delete'}   = "delete/extract/$extract_id";
        }
      }
    }
    push(@extra_attr_extract_data, $extract_row);
  }

  $dbh_k->disconnect();
  $dbh_m->disconnect();

  return ($err, $msg, \@extra_attr_extract_data);
}

sub list_extract_runmode {

=pod list_extract_HELP_START
{
"OperationName" : "List extracts",
"Description": "List DNA extracts available in the system. Use filtering to retrieve desired subset or list current list of extracts attached to analysis group.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 0,
"AccessibleHTTPMethod": [{"MethodName": "POST"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Extract PlateName='Plate_8228736' Status='' WellCol='1' WellRow='A' GenotypeId='0' Tissue='0' PlateId='1' Quality='' ItemGroupName='ITM_GRP6300825' ExtractId='2' delete='delete/extract/2' ParentExtractId='0' ItemGroupId='1' update='update/extract/2' /><Extract PlateName='' Status='' WellCol='1' WellRow='A' GenotypeId='0' Tissue='0' PlateId='0' Quality='' ItemGroupName='ITM_GRP6300825' ExtractId='1' delete='delete/extract/1' ParentExtractId='0' ItemGroupId='1' update='update/extract/1' /><RecordMeta TagName='Extract' /></DATA>",
"SuccessMessageJSON": "{'VCol' : [],'Extract' : [{'PlateName' : null,'WellRow' : 'A','WellCol' : '1','Status' : '','GenotypeId' : '0','Tissue' : '0','PlateId' : '0','ItemGroupName' : 'ITM_GRP6300825','Quality' : '','delete' : 'delete/extract/1','ExtractId' : '1','ParentExtractId' : '0','update' : 'update/extract/1','ItemGroupId' : '1'}],'RecordMeta' : [{'TagName' : 'Extract'}]}",
"ErrorMessageXML": [{"UnexpectedError": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='Unexpected Error.' /></DATA>"}],
"ErrorMessageJSON": [{"UnexpectedError": "{'Error' : [{'Message' : 'Unexpected Error.' }]}"}],
"URLParameter": [{"ParameterName": "analid", "Description": "Existing AnalysisGroupId", "Optional": 1}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self  = shift;

  my $data_for_postrun_href = {};

  my $dbh_k = connect_kdb_read();
  my $dbh_m = connect_mdb_read();
  my $field_list = ['*', 'plate.PlateName'];

  my $anal_id = '';

  if (defined $self->param('analid')) {

    $anal_id = $self->param('analid');

    if (!record_existence($dbh_m, 'analysisgroup', 'AnalysisGroupId', $anal_id)) {

      my $err_msg = "AnalsysiGroup ($anal_id): not found.";

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }

    my $group_id  = $self->authen->group_id();
    my $gadmin_status = $self->authen->gadmin_status();

    my ($is_anal_grp_ok, $trouble_anal_id_aref) = check_permission($dbh_m, 'analysisgroup', 'AnalysisGroupId',
                                                                   [$anal_id], $group_id, $gadmin_status,
                                                                   $READ_PERM);

    if (!$is_anal_grp_ok) {

      my $err_msg = "AnalsysiGroup ($anal_id): permission denied.";

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  my $other_join = ' LEFT JOIN plate ON extract.PlateId = plate.PlateId ';
  $other_join   .= ' LEFT JOIN analgroupextract ON analgroupextract.ExtractId = extract.ExtractId ';

  my ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m,
                                                                         $dbh_k,
                                                                         $field_list,
                                                                         'extract',
                                                                         'ExtractId',
                                                                         $other_join);

  $dbh_m->disconnect();
  $dbh_k->disconnect();

  if (length($anal_id) > 0) {

    my $filter_by_analysis_group = " WHERE AnalysisGroupId = $anal_id ";
    $sql  =~ s/GROUP BY/ $filter_by_analysis_group GROUP BY /;
  }

  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  $sql   .= ' ORDER BY extract.ExtractId DESC';

  $self->logger->debug("SQL with VCol: $sql");

  my ($read_extract_err, $read_extract_msg, $extract_data) = $self->list_extract(1, $sql);

  if ($read_extract_err) {

    $self->logger->debug($read_extract_msg);
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }
  
  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Extract' => $extract_data,
                                           'VCol'         => $vcol_list,
                                           'RecordMeta'   => [{'TagName' => 'Extract'}],
  };

  return $data_for_postrun_href;
}

sub add_extract_runmode {

=pod add_extract_gadmin_HELP_START
{
"OperationName" : "Add extract",
"Description": "Add a new DNA extract into the system.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"KDDArTModule": "marker",
"KDDArTTable": "extract",
"KDDArTFactorTable": "extractfactor",
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><ReturnId Value='21' ParaName='ExtractId' /><Info Message='Extract (21) has been added successfully.' /></DATA>",
"SuccessMessageJSON": "{'ReturnId' : [{'Value' : '22','ParaName' : 'ExtractId'}],'Info' : [{'Message' : 'Extract (22) has been added successfully.'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error GenotypeId='Genotype (460) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'GenotypeId' : 'Genotype (460) not found.'}]}"}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self  = shift;
  my $query = $self->query();

  my $data_for_postrun_href = {};

  my $ItemGroupId = $query->param('ItemGroupId');

  my $ParentExtractId = '0';

  if (defined($query->param('ParentExtractId'))) {

    if ($query->param('ParentExtractId') ne '0') {

      $ParentExtractId = $query->param('ParentExtractId');
    }
  }

  my $PlateId = '0';
 
  if (defined($query->param('PlateId'))) {

    if (length($query->param('PlateId')) > 0) {

      $PlateId = $query->param('PlateId');
    }
  }

  my $GenotypeId = '0';

  if (defined($query->param('GenotypeId'))) {

    if (length($query->param('GenotypeId')) > 0) {

      $GenotypeId = $query->param('GenotypeId');
    }
  }

  my $Tissue = '0';

  if (defined($query->param('Tissue'))) {

    if (length($query->param('Tissue')) > 0) {

      $Tissue = $query->param('Tissue');
    }
  }

  my $WellRow = '';

  if (defined($query->param('WellRow'))) {

    $WellRow = $query->param('WellRow');
  }

  my $WellCol = '';

  if (defined($query->param('WellCol'))) {

    $WellCol = $query->param('WellCol');
  }

  my $Quality = '';

  if (defined($query->param('Quality'))) {

    $Quality = $query->param('Quality');
  }

  my $Status = '';

  if (defined($query->param('Status'))) {

    $Status = $query->param('Status');
  }

  my ($missing_err, $missing_href) = check_missing_href( {'ItemGroupId' => $ItemGroupId} );

  if ($missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$missing_href]};

    return $data_for_postrun_href;
  }

  my $dbh_k_read = connect_kdb_read();
  my $dbh_m_read = connect_mdb_read();

  if ($ParentExtractId ne '0') {

    if (!record_existence($dbh_m_read, 'extract', 'ExtractId', $ParentExtractId)) {

      my $err_msg = "ParentExtractId ($ParentExtractId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'ParentExtractId' => $err_msg}]};
      
      return $data_for_postrun_href;
    }
  }

  if (!record_existence($dbh_k_read, 'itemgroup', 'ItemGroupId', $ItemGroupId)) {

    my $err_msg = "ItemGroupId ($ItemGroupId) not found.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'ItemGroupId' => $err_msg}]};
    
    return $data_for_postrun_href;
  }

  my $get_geno_sql;

  if ($GenotypeId ne '0') {

    $get_geno_sql    = 'SELECT genotypespecimen.GenotypeId ';
    $get_geno_sql   .= 'FROM itemgroupentry LEFT JOIN item ON itemgroupentry.ItemId = item.ItemId ';
    $get_geno_sql   .= 'LEFT JOIN genotypespecimen ON item.SpecimenId = genotypespecimen.SpecimenId ';
    $get_geno_sql   .= 'WHERE itemgroupentry.ItemGroupId=? AND genotypespecimen.GenotypeId=?';

    my ($verify_geno_err, $verified_geno_id) = read_cell($dbh_k_read, $get_geno_sql, [$ItemGroupId, $GenotypeId]);

    if (length($verified_geno_id) == 0) {

      my $err_msg = "Genotype ($GenotypeId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'GenotypeId' => $err_msg}]};
    
      return $data_for_postrun_href;
    }
  }

  $get_geno_sql    = 'SELECT genotypespecimen.GenotypeId ';
  $get_geno_sql   .= 'FROM itemgroupentry LEFT JOIN item ON itemgroupentry.ItemId = item.ItemId ';
  $get_geno_sql   .= 'LEFT JOIN genotypespecimen ON item.SpecimenId = genotypespecimen.SpecimenId ';
  $get_geno_sql   .= 'WHERE itemgroupentry.ItemGroupId=?';

  my $seen_geno_id    = {};
  my $geno2itemgroup  = {};

  my ($get_geno_err, $get_geno_msg, $geno_data) = read_data($dbh_k_read, $get_geno_sql, [$ItemGroupId]);

  if ($get_geno_err) {

    $self->logger->debug($get_geno_msg);

    my $err_msg = "Unexpected Error.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  for my $geno_rec (@{$geno_data}) {
    
    my $geno_id = $geno_rec->{'GenotypeId'};
    $seen_geno_id->{$geno_id} = 1;
    
    $geno2itemgroup->{$geno_id} = $ItemGroupId;
  }

  my @geno_id_list = keys(%{$seen_geno_id});

  $self->logger->debug("Genotype list: " . join(',', @geno_id_list));

  my $group_id = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();

  my ($is_ok, $trouble_geno_id_aref) = check_permission($dbh_k_read, 'genotype', 'GenotypeId',
                                                        \@geno_id_list, $group_id, $gadmin_status,
                                                        $LINK_PERM);
  if (!$is_ok) {
    
    # Because a specimen can have more than one genotype, trouble item group id variable needs to be a hash
    # instead of an array so that there is no duplicate in the itemgroup id that DAL reports back to the user.
    my %trouble_itemgroup_id_list;

    for my $trouble_geno_id (@{$trouble_geno_id_aref}) {

      my $trouble_ig_id = $geno2itemgroup->{$trouble_geno_id};
      $trouble_itemgroup_id_list{$trouble_ig_id} = 1;
    }
    
    my $trouble_itemgroup_id_str = join(',', keys(%trouble_itemgroup_id_list));

    my $err_msg = 'Permission denied: ItemGroupId (' . $trouble_itemgroup_id_str . ')';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
    return $data_for_postrun_href;
  }
  
  if ($PlateId ne '0') {

    if (!record_existence($dbh_m_read, 'plate', 'PlateId', $PlateId)) {

      my $err_msg = "Plate ($PlateId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateId' => $err_msg}]};
    
      return $data_for_postrun_href;
    }

    if (length($WellRow) == 0) {

      my $err_msg = "WellRow is missing.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'WellRow' => $err_msg}]};
    
      return $data_for_postrun_href;
    }

    if (length($WellCol) == 0) {

      my $err_msg = "WellCol is missing.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'WellCol' => $err_msg}]};
    
      return $data_for_postrun_href;
    }

    my $well_pos_sql = 'SELECT CONCAT(WellRow,WellCol) AS Well FROM extract WHERE PlateId=?';
    my ($r_well_pos_err, $well_pos) = read_cell($dbh_m_read, $well_pos_sql, [$PlateId]);

    my $user_well_pos = $WellRow . $WellCol;

    if (uc($user_well_pos) eq uc($well_pos)) {

      my $err_msg = "Plate ($PlateId) already has $well_pos assigned.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
      return $data_for_postrun_href;
    }
  }

  if ($Tissue ne '0') {

    if (!type_existence($dbh_k_read, 'tissue', $Tissue)) {

      my $err_msg = "Tissue ($Tissue) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Tissue' => $err_msg}]};
    
      return $data_for_postrun_href;
    }
  }

  my $sql = "SELECT FactorId, CanFactorHaveNull, FactorValueMaxLength ";
  $sql   .= "FROM factor ";
  $sql   .= "WHERE TableNameOfFactor='extractfactor'";

  my $vcol_data = $dbh_k_read->selectall_hashref($sql, 'FactorId');

  my $vcol_param_data = {};
  my $vcol_len_info   = {};
  my $vcol_param_data_maxlen = {};

  for my $vcol_id (keys(%{$vcol_data})) {

    my $vcol_param_name = "VCol_${vcol_id}";
    my $vcol_value      = $query->param($vcol_param_name);
    if ($vcol_data->{$vcol_id}->{'CanFactorHaveNull'} != 1) {
      
      $vcol_param_data->{$vcol_param_name} = $vcol_value;
    }
    
    $vcol_len_info->{$vcol_param_name} = $vcol_data->{$vcol_id}->{'FactorValueMaxLength'};
    $vcol_param_data_maxlen->{$vcol_param_name} = $vcol_value;
  }

  my ($vcol_missing_err, $vcol_missing_href) = check_missing_href( $vcol_param_data );

  if ($vcol_missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_missing_href]};

    return $data_for_postrun_href;
  }

  my ($vcol_maxlen_err, $vcol_maxlen_href) = check_maxlen_href($vcol_param_data_maxlen, $vcol_len_info);

  if ($vcol_maxlen_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_maxlen_href]};

    return $data_for_postrun_href;
  }

  $dbh_k_read->disconnect();
  $dbh_m_read->disconnect();

  my $dbh_m_write = connect_mdb_write();

  #insert into main table
  $sql    = 'INSERT INTO extract SET ';
  $sql   .= 'ParentExtractId=?, ';
  $sql   .= 'PlateId=?, ';
  $sql   .= 'ItemGroupId=?, ';
  $sql   .= 'GenotypeId=?, ';
  $sql   .= 'Tissue=?, ';
  $sql   .= 'WellRow=?, ';
  $sql   .= 'WellCol=?, ';
  $sql   .= 'Quality=?, ';
  $sql   .= 'Status=?';

  my $sth = $dbh_m_write->prepare($sql);
  $sth->execute( $ParentExtractId, $PlateId, $ItemGroupId, $GenotypeId,
                 $Tissue, $WellRow, $WellCol, $Quality, $Status );

  my $ExtractId = -1;
  if (!$dbh_m_write->err()) {

    $ExtractId = $dbh_m_write->last_insert_id(undef, undef, 'extract', 'ExtractId');
    $self->logger->debug("ExtractId: $ExtractId");
  }
  else {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }
  $sth->finish();

  #insert into factor table
  for my $vcol_id (keys(%{$vcol_data})) {

    my $factor_value = $query->param('VCol_' . $vcol_id);

    if (length($factor_value) > 0) {

      $sql  = 'INSERT INTO extractfactor SET ';
      $sql .= 'ExtractId=?, ';
      $sql .= 'FactorId=?, ';
      $sql .= 'FactorValue=?';
      my $factor_sth = $dbh_m_write->prepare($sql);
      $factor_sth->execute($ExtractId, $vcol_id, $factor_value);

      if ($dbh_m_write->err()) {

        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

        return $data_for_postrun_href;
      }

      $factor_sth->finish();
    }
  }

  $dbh_m_write->disconnect();

  my $info_msg_aref = [{'Message' => "Extract ($ExtractId) has been added successfully."}];
  my $return_id_aref = [{'Value' => "$ExtractId", 'ParaName' => 'ExtractId'}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info'     => $info_msg_aref,
                                           'ReturnId' => $return_id_aref,
  };
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub del_extract_runmode {

=pod del_extract_gadmin_HELP_START
{
"OperationName" : "Delete extract",
"Description": "Delete DNA extract specified by id. Extract can be deleted only if not attached to any lower level related record.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 1,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Info Message='Extract (22) has been deleted successfully.' /></DATA>",
"SuccessMessageJSON": "{'Info' : [{'Message' : 'Extract (21) has been deleted successfully.'}]}",
"ErrorMessageXML": [{"IdUsed": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='Extract (8) is used by an anaysisgroup.' /></DATA>"}],
"ErrorMessageJSON": [{"IdUsed": "{'Error' : [{'Message' : 'Extract (8) is used by an anaysisgroup.'}]}"}],
"URLParameter": [{"ParameterName": "id", "Description": "Existing ExtractId."}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self       = shift;
  my $ExtractId = $self->param('id');

  my $data_for_postrun_href = {};

  my $dbh_m_read = connect_mdb_read();

  my $extract_exist = record_existence($dbh_m_read, 'extract', 'ExtractId', $ExtractId);

  if (!$extract_exist) {

    my $err_msg = "Extract ($ExtractId) not found.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $extract_in_analysisgroup = record_existence($dbh_m_read, 'analgroupextract',
                                                       'ExtractId', $ExtractId);

  if ($extract_in_analysisgroup) {

    my $err_msg = "Extract ($ExtractId) is used by an anaysisgroup.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  $dbh_m_read->disconnect();

  my $dbh_m_write = connect_mdb_write();

  my $sql = 'DELETE FROM extractfactor WHERE ExtractId=?';
  my $sth = $dbh_m_write->prepare($sql);

  $sth->execute($ExtractId);

  if ($dbh_m_write->err()) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $sth->finish();

  $sql = 'DELETE FROM extract WHERE ExtractId=?';
  $sth = $dbh_m_write->prepare($sql);

  $sth->execute($ExtractId);

  if ($dbh_m_write->err()) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $sth->finish();

  $dbh_m_write->disconnect();

  my $info_msg_aref = [{'Message' => "Extract ($ExtractId) has been deleted successfully."}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info' => $info_msg_aref};
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;

}

sub update_extract_runmode {

=pod update_extract_gadmin_HELP_START
{
"OperationName" : "Update extract",
"Description": "Update DNA extract specified by id.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 1,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"KDDArTModule": "marker",
"KDDArTTable": "extract",
"KDDArTFactorTable": "extractfactor",
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Info Message='Extract (23) has been updated successfully.' /></DATA>",
"SuccessMessageJSON": "{'Info' : [{'Message' : 'Extract (23) has been updated successfully.'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error GenotypeId='GenotypeId (460) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'GenotypeId' : 'GenotypeId (460) not found.'}]}"}],
"URLParameter": [{"ParameterName": "id", "Description": "Existing ExtractId."}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self           = shift;
  my $ExtractId      = $self->param('id');
  my $query          = $self->query();

  my $data_for_postrun_href = {};

  my $dbh_k_read = connect_kdb_read();
  my $dbh_m_read = connect_mdb_read();

  if (!record_existence($dbh_m_read, 'extract', 'ExtractId', $ExtractId)) {

    my $err_msg = "Extract ($ExtractId) not found.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
    return $data_for_postrun_href;
  }

  my $ItemGroupId = $query->param('ItemGroupId');

  my $ParentExtractId = read_cell_value($dbh_m_read, 'extract', 'ParentExtractId', 'ExtractId', $ExtractId);

  if (defined($query->param('ParentExtractId'))) {

    if ($query->param('ParentExtractId') ne '0') {

      $ParentExtractId = $query->param('ParentExtractId');
    }
  }

  if (length($ParentExtractId) == 0) {

    $ParentExtractId = '0';
  }

  my $PlateId = read_cell_value($dbh_m_read, 'extract', 'PlateId', 'ExtractId', $ExtractId);
 
  if (defined($query->param('PlateId'))) {

    if (length($query->param('PlateId')) > 0) {

      $PlateId = $query->param('PlateId');
    }
  }

  if (length($PlateId) == 0) {

    $PlateId = '0';
  }

  my $GenotypeId = read_cell_value($dbh_m_read, 'extract', 'GenotypeId', 'ExtractId', $ExtractId);

  if (defined($query->param('GenotypeId'))) {

    if (length($query->param('GenotypeId')) > 0) {

      $GenotypeId = $query->param('GenotypeId');
    }
  }

  if (length($GenotypeId) == 0) {

    $GenotypeId = '0';
  }

  my $Tissue = read_cell_value($dbh_m_read, 'extract', 'Tissue', 'ExtractId', $ExtractId);

  if (defined($query->param('Tissue'))) {

    if (length($query->param('Tissue')) > 0) {

      $Tissue = $query->param('Tissue');
    }
  }

  if (length($Tissue) == 0) {

    $Tissue = '0';
  }

  my $WellRow = read_cell_value($dbh_m_read, 'extract', 'WellRow', 'ExtractId', $ExtractId);

  if (defined($query->param('WellRow'))) {

    $WellRow = $query->param('WellRow');
  }

  my $WellCol = read_cell_value($dbh_m_read, 'extract', 'WellCol', 'ExtractId', $ExtractId);

  if (defined($query->param('WellCol'))) {

    $WellCol = $query->param('WellCol');
  }

  my $Quality = read_cell_value($dbh_m_read, 'extract', 'Quality', 'ExtractId', $ExtractId);

  if (defined($query->param('Quality'))) {

    $Quality = $query->param('Quality');
  }

  my $Status = read_cell_value($dbh_m_read, 'extract', 'Status', 'ExtractId', $ExtractId);

  if (defined($query->param('Status'))) {

    $Status = $query->param('Status');
  }

  my ($missing_err, $missing_href) = check_missing_href( {'ItemGroupId' => $ItemGroupId} );

  if ($missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$missing_href]};

    return $data_for_postrun_href;
  }

  if ($ParentExtractId ne '0') {

    if (!record_existence($dbh_m_read, 'extract', 'ExtractId', $ParentExtractId)) {

      my $err_msg = "ParentExtractId ($ParentExtractId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'ParentExtractId' => $err_msg}]};
      
      return $data_for_postrun_href;
    }
  }

  if (!record_existence($dbh_k_read, 'itemgroup', 'ItemGroupId', $ItemGroupId)) {

    my $err_msg = "ItemGroupId ($ItemGroupId) not found.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'ItemGroupId' => $err_msg}]};
    
    return $data_for_postrun_href;
  }

  my $get_geno_sql;

  if ($GenotypeId ne '0') {

    $get_geno_sql    = 'SELECT genotypespecimen.GenotypeId ';
    $get_geno_sql   .= 'FROM itemgroupentry LEFT JOIN item ON itemgroupentry.ItemId = item.ItemId ';
    $get_geno_sql   .= 'LEFT JOIN genotypespecimen ON item.SpecimenId = genotypespecimen.SpecimenId ';
    $get_geno_sql   .= 'WHERE itemgroupentry.ItemGroupId=? AND genotypespecimen.GenotypeId=?';

    my ($verify_geno_err, $verified_geno_id) = read_cell($dbh_k_read, $get_geno_sql, [$ItemGroupId, $GenotypeId]);

    if (length($verified_geno_id) == 0) {

      my $err_msg = "GenotypeId ($GenotypeId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'GenotypeId' => $err_msg}]};
    
      return $data_for_postrun_href;
    }
  }

  $get_geno_sql    = 'SELECT genotypespecimen.GenotypeId ';
  $get_geno_sql   .= 'FROM itemgroupentry LEFT JOIN item ON itemgroupentry.ItemId = item.ItemId ';
  $get_geno_sql   .= 'LEFT JOIN genotypespecimen ON item.SpecimenId = genotypespecimen.SpecimenId ';
  $get_geno_sql   .= 'WHERE itemgroupentry.ItemGroupId=?';

  my $seen_geno_id    = {};
  my $geno2itemgroup  = {};

  my ($get_geno_err, $get_geno_msg, $geno_data) = read_data($dbh_k_read, $get_geno_sql, [$ItemGroupId]);

  if ($get_geno_err) {

    $self->logger->debug($get_geno_msg);

    my $err_msg = "Unexpected Error.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  for my $geno_rec (@{$geno_data}) {
    
    my $geno_id = $geno_rec->{'GenotypeId'};
    $seen_geno_id->{$geno_id} = 1;
    
    $geno2itemgroup->{$geno_id} = $ItemGroupId;
  }

  my @geno_id_list = keys(%{$seen_geno_id});

  $self->logger->debug("Genotype list: " . join(',', @geno_id_list));

  my $group_id = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();

  my ($is_ok, $trouble_geno_id_aref) = check_permission($dbh_k_read, 'genotype', 'GenotypeId',
                                                        \@geno_id_list, $group_id, $gadmin_status,
                                                        $LINK_PERM);
  if (!$is_ok) {
    
    # Because a specimen can have more than one genotype, trouble item group id variable needs to be a hash
    # instead of an array so that there is no duplicate in the itemgroup id that DAL reports back to the user.
    my %trouble_itemgroup_id_list;

    for my $trouble_geno_id (@{$trouble_geno_id_aref}) {

      my $trouble_ig_id = $geno2itemgroup->{$trouble_geno_id};
      $trouble_itemgroup_id_list{$trouble_ig_id} = 1;
    }
    
    my $trouble_itemgroup_id_str = join(',', keys(%trouble_itemgroup_id_list));

    my $err_msg = 'Permission denied: ItemGroupId (' . $trouble_itemgroup_id_str . ')';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
    return $data_for_postrun_href;
  }
  
  if ($PlateId ne '0') {

    if (!record_existence($dbh_m_read, 'plate', 'PlateId', $PlateId)) {

      my $err_msg = "Plate ($PlateId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateId' => $err_msg}]};
    
      return $data_for_postrun_href;
    }

    if (length($WellRow) == 0) {

      my $err_msg = "WellRow is missing.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'WellRow' => $err_msg}]};
    
      return $data_for_postrun_href;
    }

    if (length($WellCol) == 0) {

      my $err_msg = "WellCol is missing.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'WellCol' => $err_msg}]};
    
      return $data_for_postrun_href;
    }

    my $well_pos_sql = 'SELECT CONCAT(WellRow,WellCol) AS Well FROM extract WHERE PlateId=? AND ExtractId <>?';
    my ($r_well_pos_err, $well_pos) = read_cell($dbh_m_read, $well_pos_sql, [$PlateId, $ExtractId]);

    my $user_well_pos = $WellRow . $WellCol;

    if (uc($user_well_pos) eq uc($well_pos)) {

      my $err_msg = "Plate ($PlateId) already has $well_pos assigned.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
      return $data_for_postrun_href;
    }
  }
  else {

    if (length($WellRow) > 0) {

      my $err_msg = "WellRow cannot be accepted while Plate is not provided.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'WellRow' => $err_msg}]};
    
      return $data_for_postrun_href;
    }

    if (length($WellCol) > 0) {

      my $err_msg = "WellCol cannot be accepted while Plate is not provided.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'WellCol' => $err_msg}]};
    
      return $data_for_postrun_href;
    }
  }

  if ($Tissue ne '0') {

    if (!type_existence($dbh_k_read, 'tissue', $Tissue)) {

      my $err_msg = "Tissue ($Tissue) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Tissue' => $err_msg}]};
    
      return $data_for_postrun_href;
    }
  }

  my $sql = "SELECT FactorId, CanFactorHaveNull, FactorValueMaxLength ";
  $sql   .= "FROM factor ";
  $sql   .= "WHERE TableNameOfFactor='extractfactor'";

  my $vcol_data = $dbh_k_read->selectall_hashref($sql, 'FactorId');

  my $vcol_param_data = {};
  my $vcol_len_info   = {};
  my $vcol_param_data_maxlen = {};

  for my $vcol_id (keys(%{$vcol_data})) {

    my $vcol_param_name = "VCol_${vcol_id}";
    my $vcol_value      = $query->param($vcol_param_name);
    if ($vcol_data->{$vcol_id}->{'CanFactorHaveNull'} != 1) {
      
      $vcol_param_data->{$vcol_param_name} = $vcol_value;
    }
    
    $vcol_len_info->{$vcol_param_name} = $vcol_data->{$vcol_id}->{'FactorValueMaxLength'};
    $vcol_param_data_maxlen->{$vcol_param_name} = $vcol_value;
  }

  my ($vcol_missing_err, $vcol_missing_href) = check_missing_href( $vcol_param_data );

  if ($vcol_missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_missing_href]};

    return $data_for_postrun_href;
  }

  my ($vcol_maxlen_err, $vcol_maxlen_href) = check_maxlen_href($vcol_param_data_maxlen, $vcol_len_info);

  if ($vcol_maxlen_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_maxlen_href]};

    return $data_for_postrun_href;
  }

  $dbh_k_read->disconnect();
  $dbh_m_read->disconnect();

  my $dbh_m_write = connect_mdb_write();

  #insert into main table
  $sql    = 'UPDATE extract SET ';
  $sql   .= 'ParentExtractId=?, ';
  $sql   .= 'PlateId=?, ';
  $sql   .= 'ItemGroupId=?, ';
  $sql   .= 'GenotypeId=?, ';
  $sql   .= 'Tissue=?, ';
  $sql   .= 'WellRow=?, ';
  $sql   .= 'WellCol=?, ';
  $sql   .= 'Quality=?, ';
  $sql   .= 'Status=?';
  $sql   .= 'WHERE ExtractId=?';

  my $sth = $dbh_m_write->prepare($sql);
  $sth->execute( $ParentExtractId, $PlateId, $ItemGroupId, $GenotypeId, $Tissue, $WellRow, $WellCol,
                 $Quality, $Status, $ExtractId );

  if ($dbh_m_write->err()) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }
  $sth->finish();

  for my $vcol_id (keys(%{$vcol_data})) {

    my $factor_value = $query->param('VCol_' . "$vcol_id");

    $sql  = 'SELECT Count(*) ';
    $sql .= 'FROM extractfactor ';
    $sql .= 'WHERE ExtractId=? AND FactorId=?';

    my ($read_err, $count) = read_cell($dbh_m_write, $sql, [$ExtractId, $vcol_id]);

    if (length($factor_value) > 0) {

      if ($count > 0) {

        $sql  = 'UPDATE extractfactor SET ';
        $sql .= 'FactorValue=? ';
        $sql .= 'WHERE ExtractId=? AND FactorId=?';

        my $factor_sth = $dbh_m_write->prepare($sql);
        $factor_sth->execute($factor_value, $ExtractId, $vcol_id);

        if ($dbh_m_write->err()) {

          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

          return $data_for_postrun_href;
        }

        $factor_sth->finish();
      }
      else {

        $sql  = 'INSERT INTO extractfactor SET ';
        $sql .= 'ExtractId=?, ';
        $sql .= 'FactorId=?, ';
        $sql .= 'FactorValue=?';

        my $factor_sth = $dbh_m_write->prepare($sql);
        $factor_sth->execute($ExtractId, $vcol_id, $factor_value);

        if ($dbh_m_write->err()) {

          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

          return $data_for_postrun_href;
        }

        $factor_sth->finish();
      }
    }
    else {

      if ($count > 0) {

        $sql  = 'DELETE FROM extractfactor ';
        $sql .= 'WHERE ExtractId=? AND FactorId=?';

        my $factor_sth = $dbh_m_write->prepare($sql);
        $factor_sth->execute($ExtractId, $vcol_id);
      
        if ($dbh_m_write->err()) {
        
          $self->logger->debug("Delete extractfactor failed");
          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

          return $data_for_postrun_href;
        }
        $factor_sth->finish();
      }
    }
  }

  $dbh_m_write->disconnect();

  my $info_msg_aref = [{'Message' => "Extract ($ExtractId) has been updated successfully."}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info' => $info_msg_aref};
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub get_extract_runmode {

=pod get_extract_HELP_START
{
"OperationName" : "Get extract",
"Description": "Get detailed information about DNA extract specified by id.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 0,
"AccessibleHTTPMethod": [{"MethodName": "POST"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Extract Status='' WellCol='1' WellRow='A' GenotypeId='0' Tissue='0' PlateId='7' ItemGroupName='ITM_GRP8407256' Quality='' ExtractId='23' delete='delete/extract/23' ParentExtractId='0' ItemGroupId='4' update='update/extract/23' /><RecordMeta TagName='Extract' /></DATA>",
"SuccessMessageJSON": "{'VCol' : [],'Extract' : [{'WellRow' : 'A','WellCol' : '1','Status' : '','GenotypeId' : '0','Tissue' : '0','PlateId' : '7','ItemGroupName' : 'ITM_GRP8407256','Quality' : '','delete' : 'delete/extract/23','ExtractId' : '23','ParentExtractId' : '0','update' : 'update/extract/23','ItemGroupId' : '4'}],'RecordMeta' : [{'TagName' : 'Extract'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='Extract (24) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'Message' : 'Extract (24) not found.'}]}"}],
"URLParameter": [{"ParameterName": "id", "Description": "Existing ExtractId"}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self         = shift;
  my $ExtractId    = $self->param('id');

  my $data_for_postrun_href = {};

  my $dbh_m = connect_mdb_read();
  my $dbh_k = connect_kdb_read();

  my $extract_exist = record_existence($dbh_m, 'extract', 'ExtractId', $ExtractId);

  if (!$extract_exist) {

    my $err_msg = "Extract ($ExtractId) not found.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $field_list = ['*'];
  my $other_join = '';

  my ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m,
                                                                         $dbh_k,
                                                                         $field_list,
                                                                         'extract',
                                                                         'ExtractId',
                                                                         $other_join);

  $dbh_m->disconnect();
  $dbh_k->disconnect();

  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $where_clause = " WHERE extract.ExtractId=? ";

  $sql =~ s/GROUP BY/ $where_clause GROUP BY /;

  my ($err, $msg, $extract_data) = $self->list_extract(1, $sql, [$ExtractId]);
  
  if ($err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Extract' => $extract_data,
                                           'VCol'         => $vcol_list,
                                           'RecordMeta'   => [{'TagName' => 'Extract'}],
  };
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub list_analysisgroup {

  my $self              = $_[0];
  my $extra_attr_yes    = $_[1];
  my $sql               = $_[2];
  my $where_para_aref   = $_[3];

  #initialise variables
  my $err = 0;
  my $msg = '';
  my $data_aref = [];

  #get marker db handle
  my $dbh_m = connect_mdb_read();
  my $dbh_k = connect_kdb_read();

  #retrieve user's credentials
  my $group_id = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();

  $self->logger->debug("AnalysisGroup permission SQL: $sql");

  #query marker db handle using sql supplied
  ($err, $msg, $data_aref) = read_data($dbh_m, $sql, $where_para_aref);

  if ($err) {

    return ($err, $msg, []);
  }

  my $type_sql       = "SELECT TypeId, TypeName FROM generaltype WHERE Class IN ('markerstate','markerquality')";

  my $anal_grp_id_aref    = [];
  my $contact_id_href     = {};
  my $sys_grp_id_href     = {};
  
  my $group_lookup   = {};
  my $type_lookup    = {};
  my $contact_lookup = {};
  my $extract_lookup = {};

  my $chk_id_err        = 0;
  my $chk_id_msg        = '';
  my $used_id_href      = {};
  my $not_used_id_href  = {};

  if ($extra_attr_yes) {

    $type_lookup  = $dbh_k->selectall_hashref($type_sql, 'TypeId');

    for my $analysisgroup_row (@{$data_aref}) {

      push(@{$anal_grp_id_aref}, $analysisgroup_row->{'AnalysisGroupId'});
      $sys_grp_id_href->{$analysisgroup_row->{'OwnGroupId'}} = 1;
      $sys_grp_id_href->{$analysisgroup_row->{'AccessGroupId'}} = 1;

      if (defined $analysisgroup_row->{'ContactId'}) {
        
        $contact_id_href->{$analysisgroup_row->{'ContactId'}} = 1;
      }
    }

    if (scalar(keys(%{$sys_grp_id_href})) > 0) {

      my $group_sql      = 'SELECT SystemGroupId, SystemGroupName FROM systemgroup ';
      $group_sql        .= 'WHERE SystemGroupId IN (' . join(',', keys(%{$sys_grp_id_href})) . ')';

      $self->logger->debug("GROUP_SQL: $group_sql");

      $group_lookup = $dbh_k->selectall_hashref($group_sql, 'SystemGroupId');

      $self->logger->debug("GROUP LOOKUP KEY: " . join(',', keys(%{$group_lookup})));
    }

    if (scalar(keys(%{$contact_id_href})) > 0) {

      my $contact_sql    = 'SELECT ContactId, ContactFirstName, ContactLastName, ';
      $contact_sql      .= "CONCAT(contact.ContactFirstName, ' ', contact.ContactLastName) AS ContactName ";
      $contact_sql      .= 'FROM contact ';
      $contact_sql      .= 'WHERE ContactId IN (' . join(',', keys(%{$contact_id_href})) . ')';

      $self->logger->debug("CONTACT_SQL: $contact_sql");

      $contact_lookup = $dbh_k->selectall_hashref($contact_sql, 'ContactId');
    }

    if (scalar(@{$anal_grp_id_aref}) > 0) {

      my $extract_sql = 'SELECT analgroupextract.AnalysisGroupId, extract.ExtractId, ItemGroupId, ';
      $extract_sql   .= 'GenotypeId, extract.PlateId, plate.PlateName, ';
      $extract_sql   .= 'WellRow, WellCol ';
      $extract_sql   .= 'FROM analgroupextract LEFT JOIN extract ON ';
      $extract_sql   .= 'analgroupextract.ExtractId = extract.ExtractId ';
      $extract_sql   .= 'LEFT JOIN plate on extract.PlateId = plate.PlateId ';
      $extract_sql   .= 'WHERE analgroupextract.AnalysisGroupId IN (' . join(',', @{$anal_grp_id_aref}) . ')';

      $self->logger->debug("Extract SQL: $extract_sql");

      my ($extract_err, $extract_msg, $extract_data) = read_data($dbh_m, $extract_sql, []);
    
      if ($extract_err) {

        return ($extract_err, $extract_msg, []);
      }

      for my $extract_row (@{$extract_data}) {

        my $anal_id = $extract_row->{'AnalysisGroupId'};

        if (defined $extract_lookup->{$anal_id}) {
          
          my $extract_aref = $extract_lookup->{$anal_id};
          delete($extract_row->{'AnalysisGroupId'});
          push(@{$extract_aref}, $extract_row);
          $extract_lookup->{$anal_id} = $extract_aref;
        }
        else {

          delete($extract_row->{'AnalysisGroupId'});
          $extract_lookup->{$anal_id} = [$extract_row];
        }
      }

      my $chk_table_aref = [{'TableName' => 'analysisgroupmarker', 'FieldName' => 'AnalysisGroupId'}];

      ($chk_id_err, $chk_id_msg,
       $used_id_href, $not_used_id_href) = id_existence_bulk($dbh_m, $chk_table_aref, $anal_grp_id_aref);

      if ($chk_id_err) {

        $self->logger->debug("Check id existence error: $chk_id_msg");
        $err = 1;
        $msg = $chk_id_msg;

        return ($err, $msg, []);
      }
    }
  }
  
  my $perm_lookup  = {'0' => 'None',
                      '1' => 'Link',
                      '2' => 'Write',
                      '3' => 'Write/Link',
                      '4' => 'Read',
                      '5' => 'Read/Link',
                      '6' => 'Read/Write',
                      '7' => 'Read/Write/Link',
  };

  my @extra_attr_analysisgroup_data;

  for my $analysisgroup_row (@{$data_aref}) {

    my $analysisgroup_id = $analysisgroup_row->{'AnalysisGroupId'};
    my $contact_id       = $analysisgroup_row->{'ContactId'};

    my $marker_state_type   = $analysisgroup_row->{'MarkerStateType'};
    my $marker_quality_type = $analysisgroup_row->{'MarkerQualityType'};

    my $own_grp_id   = $analysisgroup_row->{'OwnGroupId'};
    my $acc_grp_id   = $analysisgroup_row->{'AccessGroupId'};
    my $own_perm     = $analysisgroup_row->{'OwnGroupPerm'};
    my $acc_perm     = $analysisgroup_row->{'AccessGroupPerm'};
    my $oth_perm     = $analysisgroup_row->{'OtherPerm'};
    my $ulti_perm    = $analysisgroup_row->{'UltimatePerm'};

    #do we want extra info?
    if ($extra_attr_yes) {

      if (defined $extract_lookup->{$analysisgroup_id}) {

        $analysisgroup_row->{'Extract'} = $extract_lookup->{$analysisgroup_id};
      }

      $analysisgroup_row->{'MarkerStateTypeName'}   = $type_lookup->{$marker_state_type}->{'TypeName'};
      $analysisgroup_row->{'MarkerQualityTypeName'} = $type_lookup->{$marker_quality_type}->{'TypeName'};
      $analysisgroup_row->{'OwnGroupName'}          = $group_lookup->{$own_grp_id}->{'SystemGroupName'};
      $analysisgroup_row->{'AccessGroupName'}       = $group_lookup->{$acc_grp_id}->{'SystemGroupName'};
      $analysisgroup_row->{'OwnGroupPermission'}    = $perm_lookup->{$own_perm};
      $analysisgroup_row->{'AccessGroupPermission'} = $perm_lookup->{$acc_perm};
      $analysisgroup_row->{'OtherPermission'}       = $perm_lookup->{$oth_perm};
      $analysisgroup_row->{'UltimatePermission'}    = $perm_lookup->{$ulti_perm};

      if (defined $contact_lookup->{$contact_id}) {

        $analysisgroup_row->{'ContactFirstName'} = $contact_lookup->{$contact_id}->{'ContactFirstName'};
        $analysisgroup_row->{'ContactLastName'}  = $contact_lookup->{$contact_id}->{'ContactLastName'};
        $analysisgroup_row->{'ContactName'}      = $contact_lookup->{$contact_id}->{'ContactName'};
      }

      if (($ulti_perm & $WRITE_PERM) == $WRITE_PERM) {

        $analysisgroup_row->{'update'} = "update/analysisgroup/$analysisgroup_id";
      }

      if ($own_grp_id == $group_id) {

        $analysisgroup_row->{'chgPerm'} = "analysisgroup/$analysisgroup_id/change/permission";

        if ($gadmin_status eq '1') {

          $analysisgroup_row->{'chgOwner'} = "analysisgroup/$analysisgroup_id/change/owner";

          if ( $not_used_id_href->{$analysisgroup_id} ) {

            $analysisgroup_row->{'delete'}  = "delete/analysisgroup/$analysisgroup_id";
          }
        }
      }
    }
    push(@extra_attr_analysisgroup_data, $analysisgroup_row);
  }

  $dbh_m->disconnect();
  $dbh_k->disconnect();

  return ($err, $msg, \@extra_attr_analysisgroup_data);
}

sub list_analysisgroup_advanced_runmode {

=pod list_analysisgroup_advanced_HELP_START
{
"OperationName" : "List analysis groups",
"Description": "List analysis groups defined in the system. This listing requires pagination information.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 0,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "FILTERING"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><Pagination Page='1' NumOfRecords='1' NumOfPages='1' NumPerPage='1' /><RecordMeta TagName='AnalysisGroup' /><AnalysisGroup AnalysisGroupId='1' AccessGroupPerm='5' AccessGroupId='0' MarkerQualityType='58' MarkerStateTypeName='MarkerState Type - 3383618' MarkerQualityTypeName='MarkerQuality Type - 0659707' AccessGroupPermission='Read/Link' OtherPermission='None' chgPerm='analysisgroup/1/change/permission' OtherPerm='0' OwnGroupPerm='7' ContactId='0' OwnGroupPermission='Read/Write/Link' OwnGroupName='admin' MarkerNameColumnPosition='4' MarkerSequenceColumnPosition='1' AccessGroupName='admin' AnalysisGroupName='6089851' AnalysisGroupDescription='Testing' GenotypeMarkerStateX='-1' MarkerStateType='57' chgOwner='analysisgroup/1/change/owner' UltimatePermission='Read/Write/Link' OwnGroupId='0' update='update/analysisgroup/1' UltimatePerm='7'><Extract PlateName='' PlateId='0' WellCol='1' WellRow='A' ExtractId='8' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='2' WellRow='A' ExtractId='9' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='3' WellRow='A' ExtractId='10' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='6' WellRow='A' ExtractId='11' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='4' WellRow='A' ExtractId='12' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='5' WellRow='A' ExtractId='13' GenotypeId='0' ItemGroupId='1' /></AnalysisGroup></DATA>",
"SuccessMessageJSON": "{'Pagination' : [{'NumOfRecords' : '1','NumOfPages' : 1,'NumPerPage' : '1','Page' : '1'}],'VCol' : [],'RecordMeta' : [{'TagName' : 'AnalysisGroup'}],'AnalysisGroup' : [{'AnalysisGroupId' : '1','AccessGroupPerm' : '5','AccessGroupId' : '0','MarkerQualityType' : '58','OtherPermission' : 'None','AccessGroupPermission' : 'Read/Link','MarkerQualityTypeName' : 'MarkerQuality Type - 0659707','MarkerStateTypeName' : 'MarkerState Type - 3383618','chgPerm' : 'analysisgroup/1/change/permission','OwnGroupPerm' : '7','OtherPerm' : '0','ContactId' : '0','OwnGroupPermission' : 'Read/Write/Link','Extract' : [{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '1','ExtractId' : '8','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '2','ExtractId' : '9','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '3','ExtractId' : '10','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '6','ExtractId' : '11','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '4','ExtractId' : '12','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '5','ExtractId' : '13','GenotypeId' : '0','ItemGroupId' : '1'}],'OwnGroupName' : 'admin','MarkerNameColumnPosition' : '4','AccessGroupName' : 'admin','MarkerSequenceColumnPosition' : '1','AnalysisGroupDescription' : 'Testing','AnalysisGroupName' : '6089851','chgOwner' : 'analysisgroup/1/change/owner','MarkerStateType' : '57','GenotypeMarkerStateX' : '-1','UltimatePermission' : 'Read/Write/Link','update' : 'update/analysisgroup/1','OwnGroupId' : '0','UltimatePerm' : '7'}]}",
"ErrorMessageXML": [{"UnexpectedError": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='Unexpected Error.' /></DATA>"}],
"ErrorMessageJSON": [{"UnexpectedError": "{'Error' : [{'Message' : 'Unexpected Error.' }]}"}],
"URLParameter": [{"ParameterName": "nperpage", "Description": "Number of records in a page for pagination"}, {"ParameterName": "num", "Description": "The page number of the pagination"}],
"HTTPParameter": [{"Required": 0, "Name": "Filtering", "Description": "Filtering parameter string consisting of filtering expressions which are separated by ampersand (&) which needs to be encoded if HTTP GET method is used. Each filtering expression is composed of a database filed name, a filtering operator and the filtering value."}, {"Required": 0, "Name": "FieldList", "Description": "Comma separated value of wanted fields."}, {"Required": 0, "Name": "Sorting", "Description": "Comma separated value of SQL sorting phrases."}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self  = shift;
  my $query = $self->query();

  my $data_for_postrun_href = {};

  my $pagination  = 0;
  my $nb_per_page = -1;
  my $page        = -1;

  $self->logger->debug("Base dir: $main::kddart_base_dir");

  if ( (defined $self->param('nperpage')) && (defined $self->param('num')) ) {

    $pagination  = 1;
    $nb_per_page = $self->param('nperpage');
    $page        = $self->param('num');
  }

  my $field_list_csv = '';

  if (defined $query->param('FieldList')) {

    $field_list_csv = $query->param('FieldList');
  }

  my $filtering_csv = '';
  
  if (defined $query->param('Filtering')) {

    $filtering_csv = $query->param('Filtering');
  }

  $self->logger->debug("Filtering csv: $filtering_csv");

  my $sorting = '';

  if (defined $query->param('Sorting')) {

    $sorting = $query->param('Sorting');
  }

  #get database handles
  my $dbh_k = connect_kdb_read();
  my $dbh_m = connect_mdb_read();

  my $group_id      = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();
  my $perm_str      = permission_phrase($group_id, 0, $gadmin_status, 'analysisgroup');

  my $field_list = ['analysisgroup.*', 'VCol*'];

  my $other_join = '';

  my ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m,
                                                                         $dbh_k,
                                                                         $field_list,
                                                                         'analysisgroup',
                                                                         'AnalysisGroupId',
                                                                         $other_join);


  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $where_perm = " WHERE ((($perm_str) & $READ_PERM) = $READ_PERM) ";

  $sql =~ s/GROUP BY/ $where_perm GROUP BY /;

  $sql   .= ' ORDER BY analysisgroup.AnalysisGroupId DESC ';
  $sql   .= ' LIMIT 1';

  $self->logger->debug("SQL with VCol: $sql");

  my ($sam_r_ana_grp_err, $sam_r_ana_grp_msg, $sam_ana_grp_data) = $self->list_analysisgroup(0, $sql);

  if ($sam_r_ana_grp_err) {

    $self->logger->debug($sam_r_ana_grp_msg);
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  my @field_list_all = keys(%{$sam_ana_grp_data->[0]});

  # no field return, it means no record. error prevention
  if (scalar(@field_list_all) == 0) {
    
    push(@field_list_all, '*');
  }

  my $final_field_list = \@field_list_all;

  if (length($field_list_csv) > 0) {

    my ($sel_field_err, $sel_field_msg, $sel_field_list) = parse_selected_field($field_list_csv,
                                                                                $final_field_list,
                                                                                'AnalysisGroupId');

    if ($sel_field_err) {

      $self->logger->debug("Parse selected field failed: $sel_field_msg");
      my $err_msg = $sel_field_msg;
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }

    $final_field_list = $sel_field_list;

    if ($filtering_csv =~ /GenusId/) {

      push(@{$final_field_list}, 'GenusId');
    }
  }

  $other_join = '';

  my $field_lookup = {};
  for my $fd_name (@{$final_field_list}) {

    $field_lookup->{$fd_name} = 1;
  }

  my $compulsory_perm_fields = ['OwnGroupId',
                                'AccessGroupId',
                                'OwnGroupPerm',
                                'AccessGroupPerm',
                                'OtherPerm',
      ];

  for my $com_fd_name (@{$compulsory_perm_fields}) {

    if (length($field_lookup->{$com_fd_name}) == 0) {

      push(@{$final_field_list}, $com_fd_name);
    }
  }

  push(@{$final_field_list}, "$perm_str AS UltimatePerm");

  ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m, $dbh_k, 
                                                                      $final_field_list, 'analysisgroup',
                                                                     'AnalysisGroupId', $other_join);

  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my ($filter_err, $filter_msg, $filter_phrase, $where_arg) = parse_filtering('AnalysisGroupId',
                                                                              'analysisgroup',
                                                                              $filtering_csv,
                                                                              $final_field_list);

  $self->logger->debug("Filter phrase: $filter_phrase");

  if ($filter_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $filter_msg}]};

    return $data_for_postrun_href;
  }

  my $filter_where_phrase = '';
  if (length($filter_phrase) > 0) {

    $filter_where_phrase = " AND $filter_phrase ";
  }

  my $filtering_exp = " WHERE (($perm_str) & $READ_PERM) = $READ_PERM $filter_where_phrase ";

  my $pagination_aref    = [];
  my $paged_limit_clause = '';
  my $paged_limit_elapsed;

  if ($pagination) {

    my ($int_err, $int_err_msg) = check_integer_value( {'nperpage' => $nb_per_page,
                                                        'num'      => $page
                                                       });

    if ($int_err) {

      $int_err_msg .= ' not integer.';
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $int_err_msg}]};

      return $data_for_postrun_href;
    }

    $self->logger->debug("Filtering expression: $filtering_exp");

    my $paged_limit_start_time = [gettimeofday()];
   
    my ($pg_id_err, $pg_id_msg, $nb_records,
        $nb_pages, $limit_clause, $rcount_time) = get_paged_filter($dbh_m,
                                                                   $nb_per_page,
                                                                   $page,
                                                                   'analysisgroup',
                                                                   'AnalysisGroupId',
                                                                   $filtering_exp,
                                                                   $where_arg
            );

    $paged_limit_elapsed = tv_interval($paged_limit_start_time);

    $self->logger->debug("SQL Row count time: $rcount_time");

    if ($pg_id_err == 1) {
    
      $self->logger->debug($pg_id_msg);
    
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

      return $data_for_postrun_href;
    }

    if ($pg_id_err == 2) {
      
      $page = 0;
    }

    $pagination_aref = [{'NumOfRecords' => $nb_records,
                         'NumOfPages'   => $nb_pages,
                         'Page'         => $page,
                         'NumPerPage'   => $nb_per_page,
                        }];

    $paged_limit_clause = $limit_clause;
  }

  $dbh_k->disconnect();
  $dbh_m->disconnect();

  $sql  =~ s/GROUP BY/ $filtering_exp GROUP BY /;

  my ($sort_err, $sort_msg, $sort_sql) = parse_sorting($sorting, $final_field_list);

  if ($sort_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $sort_msg}]};

    return $data_for_postrun_href;
  }

  if (length($sort_sql) > 0) {

    $sql .= " ORDER BY $sort_sql ";
  }
  else {

    $sql .= ' ORDER BY analysisgroup.AnalysisGroupId DESC';
  }

  $sql .= " $paged_limit_clause ";

  $self->logger->debug("SQL with VCol: $sql");


  my ($r_ana_grp_err, $r_ana_grp_msg, $ana_grp_data) = $self->list_analysisgroup(1, $sql, $where_arg);

  if ($r_ana_grp_err) {

    $self->logger->debug($r_ana_grp_msg);
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'AnalysisGroup' => $ana_grp_data,
                                           'VCol'          => $vcol_list,
                                           'Pagination'    => $pagination_aref,
                                           'RecordMeta'    => [{'TagName' => 'AnalysisGroup'}],
  };
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub get_analysisgroup_runmode {

=pod get_analysisgroup_HELP_START
{
"OperationName" : "Get analysis group",
"Description": "Get detailed information about the analysis group specified by id.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 0,
"AccessibleHTTPMethod": [{"MethodName": "POST"}, {"MethodName": "GET"}],
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><RecordMeta TagName='AnalysisGroup' /><AnalysisGroup AnalysisGroupId='1' AccessGroupPerm='5' AccessGroupId='0' MarkerQualityType='58' MarkerStateTypeName='MarkerState Type - 3383618' MarkerQualityTypeName='MarkerQuality Type - 0659707' AccessGroupPermission='Read/Link' OtherPermission='None' chgPerm='analysisgroup/1/change/permission' OwnGroupPerm='7' OtherPerm='0' ContactId='0' OwnGroupPermission='Read/Write/Link' OwnGroupName='admin' MarkerNameColumnPosition='4' MarkerSequenceColumnPosition='1' AccessGroupName='admin' AnalysisGroupDescription='Testing' AnalysisGroupName='6089851' MarkerStateType='57' GenotypeMarkerStateX='-1' chgOwner='analysisgroup/1/change/owner' UltimatePermission='Read/Write/Link' OwnGroupId='0' update='update/analysisgroup/1' UltimatePerm='7'><Extract PlateName='' PlateId='0' WellCol='1' WellRow='A' ExtractId='8' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='2' WellRow='A' ExtractId='9' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='3' WellRow='A' ExtractId='10' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='6' WellRow='A' ExtractId='11' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='4' WellRow='A' ExtractId='12' GenotypeId='0' ItemGroupId='1' /><Extract PlateName='' PlateId='0' WellCol='5' WellRow='A' ExtractId='13' GenotypeId='0' ItemGroupId='1' /></AnalysisGroup></DATA>",
"SuccessMessageJSON": "{'VCol' : [],'RecordMeta' : [{'TagName' : 'AnalysisGroup'}],'AnalysisGroup' : [{'AnalysisGroupId' : '1','AccessGroupPerm' : '5','AccessGroupId' : '0','MarkerQualityType' : '58','OtherPermission' : 'None','AccessGroupPermission' : 'Read/Link','MarkerQualityTypeName' : 'MarkerQuality Type - 0659707','MarkerStateTypeName' : 'MarkerState Type - 3383618','chgPerm' : 'analysisgroup/1/change/permission','OtherPerm' : '0','OwnGroupPerm' : '7','ContactId' : '0','OwnGroupPermission' : 'Read/Write/Link','Extract' : [{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '1','ExtractId' : '8','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '2','ExtractId' : '9','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '3','ExtractId' : '10','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '6','ExtractId' : '11','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '4','ExtractId' : '12','GenotypeId' : '0','ItemGroupId' : '1'},{'PlateName' : null,'PlateId' : '0','WellRow' : 'A','WellCol' : '5','ExtractId' : '13','GenotypeId' : '0','ItemGroupId' : '1'}],'OwnGroupName' : 'admin','MarkerNameColumnPosition' : '4','AccessGroupName' : 'admin','MarkerSequenceColumnPosition' : '1','AnalysisGroupName' : '6089851','AnalysisGroupDescription' : 'Testing','chgOwner' : 'analysisgroup/1/change/owner','GenotypeMarkerStateX' : '-1','MarkerStateType' : '57','UltimatePermission' : 'Read/Write/Link','update' : 'update/analysisgroup/1','OwnGroupId' : '0','UltimatePerm' : '7'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error Message='AnalysisGroup (5): not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'Message' : 'AnalysisGroup (5): not found.'}]}"}],
"URLParameter": [{"ParameterName": "id", "Description": "Existing AnalysisGroupId"}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self            = shift;
  my $analysis_grp_id = $self->param('id');

  my $data_for_postrun_href = {};

  #get database handles
  my $dbh_k = connect_kdb_read();
  my $dbh_m = connect_mdb_read();

  if (!record_existence($dbh_m, 'analysisgroup', 'AnalysisGroupId', $analysis_grp_id)) {

    my $err_msg = "AnalysisGroup ($analysis_grp_id): not found.";
    return $self->_set_error($err_msg);
  }

  my $group_id      = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();
  my $perm_str      = permission_phrase($group_id, 0, $gadmin_status, 'analysisgroup');

  my $field_list = ['*', "$perm_str AS UltimatePerm"];

  my $other_join = '';

  my ($vcol_err, $trouble_vcol, $sql, $vcol_list) = generate_mfactor_sql($dbh_m,
                                                                         $dbh_k,
                                                                         $field_list,
                                                                         'analysisgroup',
                                                                         'AnalysisGroupId',
                                                                         $other_join);

  $dbh_m->disconnect();
  $dbh_k->disconnect();

  if ($vcol_err) {

    my $err_msg = "Problem with virtual column ($trouble_vcol) containing space.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $where_clause = " WHERE ((($perm_str) & $READ_PERM) = $READ_PERM) AND analysisgroup.AnalysisGroupId=? ";
  
  $sql   =~ s/GROUP BY/ $where_clause GROUP BY /;

  $sql   .= ' ORDER BY analysisgroup.AnalysisGroupId DESC';

  $self->logger->debug("SQL with VCol: $sql");

  my ($read_ana_grp_err, $read_ana_grp_msg, $ana_grp_data) = $self->list_analysisgroup(1, $sql,
                                                                                       [$analysis_grp_id] );

  if ($read_ana_grp_err) {

    $self->logger->debug($read_ana_grp_msg);
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'AnalysisGroup' => $ana_grp_data,
                                           'VCol'          => $vcol_list,
                                           'RecordMeta'    => [{'TagName' => 'AnalysisGroup'}],
  };
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub add_analysisgroup_runmode {

=pod add_analysisgroup_HELP_START
{
"OperationName" : "Add analysis group",
"Description": "Add a new analysis group definition. This groups DNA extracts which will undergo genotyping experiment together.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"KDDArTModule": "marker",
"KDDArTTable": "analysisgroup",
"KDDArTFactorTable": "analysisgroupfactor",
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><ReturnId ParaName='AnalysisGroupId' Value='2' /><Info Message='AnalysisGroup (2) has been added successfully.' /></DATA>",
"SuccessMessageJSON": "{'ReturnId' : [{'Value' : '3','ParaName' : 'AnalysisGroupId'}],'Info' : [{'Message' : 'AnalysisGroup (3) has been added successfully.'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error MarkerStateType='MarkerStateType (252) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'MarkerStateType' : 'MarkerStateType (252) not found.'}]}"}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self  = shift;
  my $query = $self->query();

  my $data_for_postrun_href = {};

  # Generic required static field checking

  my $dbh_read = connect_mdb_read();

  my $skip_field = { 'GenotypeMarkerStateX' => 1,
                     'OwnGroupId'           => 1,
  };

  my ($get_scol_err, $get_scol_msg, $scol_data, $pkey_data) = get_static_field($dbh_read, 'analysisgroup');

  if ($get_scol_err) {

    $self->logger->debug("Get static field info failed: $get_scol_msg");
    
    my $err_msg = "Unexpected Error.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $required_field_href = {};

  for my $static_field (@{$scol_data}) {

    my $field_name = $static_field->{'Name'};
    
    if ($skip_field->{$field_name}) { next; }

    if ($static_field->{'Required'} == 1) {

      $required_field_href->{$field_name} = $query->param($field_name);
    }
  }

  $dbh_read->disconnect();

  my ($missing_err, $missing_href) = check_missing_href( $required_field_href );

  if ($missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$missing_href]};

    return $data_for_postrun_href;
  }

  # Finish generic required static field checking

  my $AnalysisGroupName         = $query->param('AnalysisGroupName');
  my $MarkerStateType           = $query->param('MarkerStateType');
  my $MarkerQualityType         = $query->param('MarkerQualityType');
  my $AccessGroupId             = $query->param('AccessGroupId');
  my $OwnGroupPerm              = $query->param('OwnGroupPerm');
  my $AccessGroupPerm           = $query->param('AccessGroupPerm');
  my $OtherPerm                 = $query->param('OtherPerm');

  my $AnalysisGroupDescription  = '';

  if (defined($query->param('AnalysisGroupDescription'))) {

    $AnalysisGroupDescription = $query->param('AnalysisGroupDescription');
  }
  
  my $ContactId                 = '0';

  if (defined($query->param('ContactId'))) {

    if (length($query->param('ContactId')) > 0) {

      $ContactId = $query->param('ContactId');
    }
  }

  $self->logger->debug('Adding Analysis Group');

  my $dbh_k_read = connect_kdb_read();
  my $dbh_m_read = connect_mdb_read();

  my $sql = "SELECT FactorId, CanFactorHaveNull, FactorValueMaxLength ";
  $sql   .= "FROM factor ";
  $sql   .= "WHERE TableNameOfFactor='analysisgroupfactor'";

  my $vcol_data = $dbh_k_read->selectall_hashref($sql, 'FactorId');

  my $vcol_param_data = {};
  my $vcol_len_info   = {};
  my $vcol_param_data_maxlen = {};
  for my $vcol_id (keys(%{$vcol_data})) {

    my $vcol_param_name = "VCol_${vcol_id}";
    my $vcol_value      = $query->param($vcol_param_name);
    if ($vcol_data->{$vcol_id}->{'CanFactorHaveNull'} != 1) {

      $vcol_param_data->{$vcol_param_name} = $vcol_value;
    }

    $vcol_len_info->{$vcol_param_name} = $vcol_data->{$vcol_id}->{'FactorValueMaxLength'};
    $vcol_param_data_maxlen->{$vcol_param_name} = $vcol_value;
  }

  my ($vcol_missing_err, $vcol_missing_href) = check_missing_href( $vcol_param_data );

  if ($vcol_missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_missing_href]};

    return $data_for_postrun_href;
  }

  my ($vcol_maxlen_err, $vcol_maxlen_href) = check_maxlen_href($vcol_param_data_maxlen, $vcol_len_info);

  if ($vcol_maxlen_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_maxlen_href]};

    return $data_for_postrun_href;
  }

  if (record_existence($dbh_m_read, 'analysisgroup', 'AnalysisGroupName', $AnalysisGroupName)) {

    my $err_msg = "AnalysisGroupName ($AnalysisGroupName) already exists.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'AnalysisGroupName' => $err_msg}]};

    return $data_for_postrun_href;
  }
  
  #check that supplied access group exists
  my $access_grp_existence = record_existence($dbh_k_read, 'systemgroup', 'SystemGroupId', $AccessGroupId);

  if (!$access_grp_existence) {

    my $err_msg = "AccessGroup ($AccessGroupId) does not exist.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'AccessGroupId' => $err_msg}]};

    return $data_for_postrun_href;
  }

  #check that permission values fall within accepted constraints
  if ( $OwnGroupPerm > 7 || $OwnGroupPerm < 0 || 
        (($OwnGroupPerm & $READ_PERM) != $READ_PERM) ) {

    my $err_msg = "OwnGroupPerm ($OwnGroupPerm) is invalid.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'OwnGroupPerm' => $err_msg}]};

    return $data_for_postrun_href;
  }

  if ( ($AccessGroupPerm > 7 || $AccessGroupPerm < 0) ) {

    my $err_msg = "AccessGroupPerm ($AccessGroupPerm) is invalid.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'AccessGroupPerm' => $err_msg}]};

    return $data_for_postrun_href;
  }

  if ( ($OtherPerm > 7 || $OtherPerm < 0) ) {

    my $err_msg = "OtherPerm ($OtherPerm) is invalid.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'OtherPerm' => $err_msg}]};

    return $data_for_postrun_href;
  }

  if (!type_existence($dbh_k_read, 'markerstate', $MarkerStateType)) {

    my $err_msg = "MarkerStateType ($MarkerStateType) not found.";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'MarkerStateType' => $err_msg}]};

    return $data_for_postrun_href;
  }

  if (!type_existence($dbh_k_read, 'markerquality', $MarkerQualityType)) {

    my $err_msg = "MarkerQualityType ($MarkerQualityType) not found.";

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'MarkerQualityType' => $err_msg}]};

      return $data_for_postrun_href;
  }

  if ($ContactId ne '0') {

    if (!record_existence($dbh_k_read, 'contact', 'ContactId', $ContactId)) {

      my $err_msg = "Contact ($ContactId) not found.";

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'ContactId' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  my $extract_xml_file = $self->authen->get_upload_file();

  my $analysisgroup_dtd_file = $self->get_analysisgroup_dtd_file();

  add_dtd($analysisgroup_dtd_file, $extract_xml_file);

  my $xml_checker_parser = new XML::Checker::Parser( Handlers => { } );

  eval {

    local $XML::Checker::FAIL = sub {
      
      my $code = shift;
      my $err_str = XML::Checker::error_string ($code, @_);
      $self->logger->debug("XML Parsing ERR: $code : $err_str");
      die $err_str;
    };
    $xml_checker_parser->parsefile($extract_xml_file);
  };

  if ($@) {

    my $err_msg = $@;
    $self->logger->debug("Parsing XML error: $err_msg");
    my $user_err_msg = "Analysis Group xml file does not comply with its definition.\n";
    $user_err_msg   .= "Details: $err_msg";

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $user_err_msg}]};

    return $data_for_postrun_href;
  }

  my $extract_xml  = read_file($extract_xml_file);
  my $extract_aref = xml2arrayref($extract_xml_file, 'extract');

  my @ExtractIds;
  my $seen_geno_id = {};
  my $geno2extract = {};

  $sql    = 'SELECT genotypespecimen.GenotypeId ';
  $sql   .= 'FROM itemgroupentry LEFT JOIN item ON itemgroupentry.ItemId = item.ItemId ';
  $sql   .= 'LEFT JOIN genotypespecimen ON item.SpecimenId = genotypespecimen.SpecimenId ';
  $sql   .= 'WHERE itemgroupentry.ItemId=?';

  for my $Extract (@{$extract_aref}) {

    my $ExtractId = $Extract->{'ExtractId'};

    if (!record_existence($dbh_m_read, 'extract', 'ExtractId', $ExtractId)) {

      my $err_msg = "Extract ($ExtractId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }

    my $item_group_id = read_cell_value($dbh_m_read, 'extract', 'ItemGroupId', 'ExtractId', $ExtractId);

    my ($get_geno_err, $get_geno_msg, $geno_data) = read_data($dbh_k_read, $sql, [$item_group_id]);

    if ($get_geno_err) {

      $self->logger->debug($get_geno_msg);

      my $err_msg = "Unexpected Error.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }

    for my $geno_rec (@{$geno_data}) {

      my $geno_id = $geno_rec->{'GenotypeId'};
      $seen_geno_id->{$geno_id} = 1;

      $geno2extract->{$geno_id} = $ExtractId;
    }
  }

  my @geno_id_list = keys(%{$seen_geno_id});

  my $group_id = $self->authen->group_id();
  my $gadmin_status = $self->authen->gadmin_status();

  my ($is_ok, $trouble_geno_id_aref) = check_permission($dbh_k_read, 'genotype', 'GenotypeId',
                                                        \@geno_id_list, $group_id, $gadmin_status, 
                                                        $LINK_PERM);
  if (!$is_ok) {
    
    my @trouble_ext_id_list;

    for my $trouble_geno_id (@{$trouble_geno_id_aref}) {

      my $trouble_ext_id = $geno2extract->{$trouble_geno_id};
      push(@trouble_ext_id_list, $trouble_ext_id);
    }

    my $trouble_ext_id_str = join(',', @trouble_ext_id_list);

    my $err_msg = 'Permission denied: ExtractIds (' . $trouble_ext_id_str . ')';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
    return $data_for_postrun_href;
  }

  $dbh_k_read->disconnect();
  $dbh_m_read->disconnect();

  my $dbh_m_write = connect_mdb_write();

  my $default_genotype_marker_state_x = 0;    # let the importation of marker data to decide

  #insert into main table
  $sql    = 'INSERT INTO analysisgroup SET ';
  $sql   .= 'AnalysisGroupName=?, ';
  $sql   .= 'AnalysisGroupDescription=?, ';
  $sql   .= 'GenotypeMarkerStateX=?, ';
  $sql   .= 'MarkerStateType=?, ';
  $sql   .= 'MarkerQualityType=?, ';
  $sql   .= 'ContactId=?, ';
  $sql   .= 'OwnGroupId=?, ';
  $sql   .= 'AccessGroupId=?, ';
  $sql   .= 'OwnGroupPerm=?, ';
  $sql   .= 'AccessGroupPerm=?, ';
  $sql   .= 'OtherPerm=?';

  my $sth = $dbh_m_write->prepare($sql);
  $sth->execute(
                $AnalysisGroupName,
                $AnalysisGroupDescription,
                $default_genotype_marker_state_x,
                $MarkerStateType,
                $MarkerQualityType,
                $ContactId,
                $group_id,
                $AccessGroupId,
                $OwnGroupPerm,
                $AccessGroupPerm,
                $OtherPerm
   );

  my $AnalysisGroupId = -1;

  my $inserted_id = {};

  if (!$dbh_m_write->err()) {

    $AnalysisGroupId = $dbh_m_write->last_insert_id(undef, undef, 'analysisgroup', 'AnalysisGroupId');
    $self->logger->debug("AnalysisGroupId: $AnalysisGroupId");

    if ( !(defined($inserted_id->{'analysisgroup'})) ) {

      $inserted_id->{'analysisgroup'} = { 'IdField' => 'AnalysisGroupId',
                                          'IdValue' => [$AnalysisGroupId] };
    }
  }
  else {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }
  $sth->finish();

  #insert into factor table
  for my $vcol_id (keys(%{$vcol_data})) {

    my $factor_value = $query->param('VCol_' . $vcol_id);

    if (length($factor_value) > 0) {

      $sql  = 'INSERT INTO analysisgroupfactor SET ';
      $sql .= 'AnalysisGroupId=?, ';
      $sql .= 'FactorId=?, ';
      $sql .= 'FactorValue=?';
      my $factor_sth = $dbh_m_write->prepare($sql);
      $factor_sth->execute($AnalysisGroupId, $vcol_id, $factor_value);

      if ($dbh_m_write->err()) {

        my ($rollback_err, $rollback_msg) = rollback_cleanup_multi($self->logger(), $dbh_m_write, $inserted_id);

        if ($rollback_err) {

          $self->logger->debug("Rollback error: $rollback_msg");

          my $err_msg = 'Unexpected Error.';

          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
          return $data_for_postrun_href;
        }

        my $err_msg = 'Unexpected Error.';

        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
        return $data_for_postrun_href;
      }

      if ( !(defined($inserted_id->{'analysisgroupfactor'})) ) {

        $inserted_id->{'analysisgroupfactor'} = { 'IdField' => 'AnalysisGroupId',
                                                  'IdValue' => [$AnalysisGroupId] };
      }

      $factor_sth->finish();
    }
  }

  $sql  = 'INSERT INTO analgroupextract ';
  $sql .= '(AnalysisGroupId,ExtractId) ';
  $sql .= 'VALUES ';

  my @sql_row;

  foreach my $extract_rec (@{$extract_aref}) {

    my $ExtractId = $extract_rec->{'ExtractId'};
    push(@sql_row, "($AnalysisGroupId, $ExtractId)" );
  }

  $sql .= join(',', @sql_row);

  my $extracts_sth = $dbh_m_write->prepare($sql);
  $extracts_sth->execute();

  if ($dbh_m_write->err()) {

    $self->logger->debug("SQL err: " . $dbh_m_write->errstr());

    my ($rollback_err, $rollback_msg) = rollback_cleanup_multi($self->logger(), $dbh_m_write, $inserted_id);

    if ($rollback_err) {

      $self->logger->debug("Rollback error: $rollback_msg");

      my $err_msg = 'Unexpected Error.';

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
      return $data_for_postrun_href;
    }

    my $err_msg = 'Unexpected Error.';

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
    return $data_for_postrun_href;
  }

  $dbh_m_write->disconnect();

  my $info_msg_aref  = [{'Message' => "AnalysisGroup ($AnalysisGroupId) has been added successfully."}];
  my $return_id_aref = [{'Value' => "$AnalysisGroupId", 'ParaName' => 'AnalysisGroupId'}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info'     => $info_msg_aref,
                                           'ReturnId' => $return_id_aref,
  };
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub add_plate_n_extract_runmode {

=pod add_plate_n_extract_gadmin_HELP_START
{
"OperationName" : "Add plate with extracts",
"Description": "Add DNA plate and extracts together. Allows to define entire plate and contents in one call.",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 1,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"KDDArTModule": "marker",
"KDDArTTable": "plate",
"KDDArTFactorTable": "platefactor",
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><ReturnId ParaName='PlateId' Value='8' /><Info Message='Plate (8) has been added successfully.' /></DATA>",
"SuccessMessageJSON": "{'ReturnId' : [{'Value' : '9','ParaName' : 'PlateId'}],'Info' : [{'Message' : 'Plate (9) has been added successfully.'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error PlateType='PlateType (251) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'PlateType' : 'PlateType (251) not found.'}]}"}],
"RequiredUpload": 1,
"UploadFileFormat": "XML",
"UploadFileParameterName": "uploadfile",
"DTDFileNameForUploadXML": "extract_all_field.dtd",
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self  = shift;
  my $query = $self->query();

  my $data_for_postrun_href = {};

  # Generic required static field checking

  my $dbh_read = connect_mdb_read();

  my $skip_field = {'DateCreated' => 1};

  my ($get_scol_err, $get_scol_msg, $scol_data, $pkey_data) = get_static_field($dbh_read, 'plate');

  if ($get_scol_err) {

    $self->logger->debug("Get static field info failed: $get_scol_msg");
    
    my $err_msg = "Unexpected Error.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $required_field_href = {};

  for my $static_field (@{$scol_data}) {

    my $field_name = $static_field->{'Name'};
    
    if ($skip_field->{$field_name}) { next; }

    if ($static_field->{'Required'} == 1) {

      $required_field_href->{$field_name} = $query->param($field_name);
    }
  }

  $dbh_read->disconnect();

  my ($missing_err, $missing_href) = check_missing_href( $required_field_href );

  if ($missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$missing_href]};

    return $data_for_postrun_href;
  }

  # Finish generic required static field checking

  my $PlateName        = $query->param('PlateName');
 
  my $OperatorId       = $query->param('OperatorId');

  my $PlateType        = '0';

  if (defined($query->param('PlateType'))) {

    if (length($query->param('PlateType')) > 0) {

      $PlateType = $query->param('PlateType');
    }
  }
  
  my $PlateDescription = '';

  if (defined($query->param('PlateDescription'))) {

    $PlateDescription = $query->param('PlateDescription');
  }

  my $StorageId        = '0';

  if (defined($query->param('StorageId'))) {

    $StorageId = $query->param('StorageId');
  }

  my $PlateWells       = '';

  if (defined($query->param('PlateWells'))) {

    $PlateWells = $query->param('PlateWells');
  }

  my $PlateStatus      = '';

  if (defined($query->param('PlateStatus'))) {

    $PlateStatus = $query->param('PlateStatus');
  }

  if (length($PlateWells) > 0) {

    my ($int_err, $int_href) = check_integer_href( {'PlateWells' => $PlateWells} );

    if ($int_err) {

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [$int_href]};

      return $data_for_postrun_href;
    }
  }

  $self->logger->debug("Plate name: $PlateName");

  my $sql = "SELECT FactorId, CanFactorHaveNull, FactorValueMaxLength ";
  $sql   .= "FROM factor ";
  $sql   .= "WHERE TableNameOfFactor='platefactor'";

  my $dbh_k_read = connect_kdb_read();
  my $vcol_data = $dbh_k_read->selectall_hashref($sql, 'FactorId');

  my $vcol_param_data = {};
  my $vcol_len_info   = {};
  my $vcol_param_data_maxlen = {};
  for my $vcol_id (keys(%{$vcol_data})) {

    my $vcol_param_name = "VCol_${vcol_id}";
    my $vcol_value      = $query->param($vcol_param_name);
    if ($vcol_data->{$vcol_id}->{'CanFactorHaveNull'} != 1) {

      $vcol_param_data->{$vcol_param_name} = $vcol_value;
    }

    $vcol_len_info->{$vcol_param_name} = $vcol_data->{$vcol_id}->{'FactorValueMaxLength'};
    $vcol_param_data_maxlen->{$vcol_param_name} = $vcol_value;
  }

  my ($vcol_missing_err, $vcol_missing_href) = check_missing_href( $vcol_param_data );

  if ($vcol_missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_missing_href]};

    return $data_for_postrun_href;
  }

  my ($vcol_maxlen_err, $vcol_maxlen_href) = check_maxlen_href($vcol_param_data_maxlen, $vcol_len_info);

  if ($vcol_maxlen_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_maxlen_href]};

    return $data_for_postrun_href;
  }

  if (!record_existence($dbh_k_read, 'systemuser', 'UserId', $OperatorId)) {

    my $err_msg = "OperatorId ($OperatorId) not found.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  if ($PlateType ne '0') {

    if (!type_existence($dbh_k_read, 'plate', $PlateType)) {

      my $err_msg = "PlateType ($PlateType) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateType' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  if ($StorageId ne '0') {

    if ( !record_existence($dbh_k_read, 'storage', 'StorageId', $StorageId) ) {

      my $err_msg = "StorageId ($StorageId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  my $dbh_m_read = connect_mdb_read();

  if (record_existence($dbh_m_read, 'plate', 'PlateName', $PlateName)) {

    my $err_msg = " ($PlateName) already exists.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateName' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $cur_dt = DateTime->now( time_zone => $TIMEZONE );
  $cur_dt = DateTime::Format::MySQL->format_datetime($cur_dt);

  my $DateCreated = $cur_dt;

  my $extract_xml_file = $self->authen->get_upload_file();
  my $extract_dtd_file = $self->get_extract_all_field_dtd_file();

  add_dtd($extract_dtd_file, $extract_xml_file);

  $self->logger->debug("Extract XML file: $extract_xml_file");

  my $xml_checker_parser = new XML::Checker::Parser( Handlers => { } );

  eval {

    local $XML::Checker::FAIL = sub {

      my $code = shift;
      my $err_str = XML::Checker::error_string ($code, @_);
      $self->logger->debug("XML Parsing ERR: $code : $err_str");
      die $err_str;
    };
    $xml_checker_parser->parsefile($extract_xml_file);
  };

  if ($@) {

    my $err_msg = $@;
    $self->logger->debug("Parsing XML error: $err_msg");
    my $user_err_msg = "Extract xml file does not comply with its definition.\n";
    $user_err_msg   .= "Details: $err_msg";

    $data_for_postrun_href->{'Error'}       = 1;
    $data_for_postrun_href->{'Data'}        = {'Error' => [{'Message' => $user_err_msg}]};

    return $data_for_postrun_href;
  }

  my $extract_xml  = read_file($extract_xml_file);
  my $extract_aref = xml2arrayref($extract_xml, 'extract');

  my $seen_geno_id    = {};
  my $geno2itemgroup  = {};

  my $uniq_well       = {};

  for my $extract_rec (@{$extract_aref}) {

    my $ItemGroupId = $extract_rec->{'ItemGroupId'};

    my $ParentExtractId = '0';

    if (defined($extract_rec->{'ParentExtractId'})) {

      if ($extract_rec->{'ParentExtractId'} ne '0') {

        $ParentExtractId = $extract_rec->{'ParentExtractId'};
      }
    }

    my $PlateId = '';

    if (defined($extract_rec->{'PlateId'})) {

      $PlateId = $extract_rec->{'PlateId'};
    }

    my $GenotypeId = '';

    if (defined($extract_rec->{'GenotypeId'})) {

      $GenotypeId = $extract_rec->{'GenotypeId'};
    }

    my $Tissue = '';

    if (defined($extract_rec->{'Tissue'})) {

      $Tissue = $extract_rec->{'Tissue'};
    }

    my $WellRow = '';

    if (defined($extract_rec->{'WellRow'})) {

      $WellRow = $extract_rec->{'WellRow'};
    }

    my $WellCol = '';

    if (defined($extract_rec->{'WellCol'})) {

      $WellCol = $extract_rec->{'WellCol'};
    }

    my $Quality = '';

    if (defined($extract_rec->{'Quality'})) {

      $Quality = $extract_rec->{'Quality'};
    }

    my $Status = '';

    if (defined($extract_rec->{'Status'})) {

      $Status = $extract_rec->{'Status'};
    }

    my ($missing_err, $missing_msg) = check_missing_value( {'ItemGroupId' => $ItemGroupId} );

    if ($missing_err) {

      $missing_msg = 'ItemGroupId is missing.';
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $missing_msg}]};

      return $data_for_postrun_href;
    }

    if ($ParentExtractId ne '0') {

      if (!record_existence($dbh_m_read, 'extract', 'ExtractId', $ParentExtractId)) {

        my $err_msg = "ParentExtractId ($ParentExtractId) not found.";
        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
        
        return $data_for_postrun_href;
      }
    }

    if (!record_existence($dbh_k_read, 'itemgroup', 'ItemGroupId', $ItemGroupId)) {

      my $err_msg = "ItemGroupId ($ItemGroupId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
      return $data_for_postrun_href;
    }

    my $get_geno_sql = '';

    if (length($GenotypeId) > 0) {
      
      $get_geno_sql    = 'SELECT genotypespecimen.GenotypeId ';
      $get_geno_sql   .= 'FROM itemgroupentry LEFT JOIN item ON itemgroupentry.ItemId = item.ItemId ';
      $get_geno_sql   .= 'LEFT JOIN genotypespecimen ON item.SpecimenId = genotypespecimen.SpecimenId ';
      $get_geno_sql   .= 'WHERE itemgroupentry.ItemGroupId=? AND genotypespecimen.GenotypeId=?';
      
      my ($verify_geno_err, $verified_geno_id) = read_cell($dbh_k_read, $get_geno_sql, [$ItemGroupId, $GenotypeId]);
      
      if (length($verified_geno_id) == 0) {
        
        my $err_msg = "GenotypeId ($GenotypeId) invalid.";
        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
        
        return $data_for_postrun_href;
      }
    }

    $get_geno_sql    = 'SELECT genotypespecimen.GenotypeId ';
    $get_geno_sql   .= 'FROM itemgroupentry LEFT JOIN item ON itemgroupentry.ItemId = item.ItemId ';
    $get_geno_sql   .= 'LEFT JOIN genotypespecimen ON item.SpecimenId = genotypespecimen.SpecimenId ';
    $get_geno_sql   .= 'WHERE itemgroupentry.ItemGroupId=?';

    my ($get_geno_err, $get_geno_msg, $geno_data) = read_data($dbh_k_read, $get_geno_sql, [$ItemGroupId]);

    if ($get_geno_err) {

      $self->logger->debug($get_geno_msg);

      my $err_msg = "Unexpected Error.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }

    for my $geno_rec (@{$geno_data}) {

      my $geno_id = $geno_rec->{'GenotypeId'};
      $seen_geno_id->{$geno_id} = 1;

      $geno2itemgroup->{$geno_id} = $ItemGroupId;
    }
      
    if (length($WellRow) == 0) {
      
      my $err_msg = "WellRow is missing.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
      return $data_for_postrun_href;
    }
    
    if (length($WellCol) == 0) {
      
      my $err_msg = "WellCol is missing.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
      return $data_for_postrun_href;
    }
    
    my $well = $WellRow . $WellCol;
    if (defined($uniq_well->{$well})) {

      my $err_msg = "Well ($well) has been used in more than one extract.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
      return $data_for_postrun_href;
    }
    else {

      $uniq_well->{$well} = 1;
    }
  }

  my @geno_id_list = keys(%{$seen_geno_id});

  my $group_id       = $self->authen->group_id();
  my $gadmin_status  = $self->authen->gadmin_status();

  my ($is_ok, $trouble_geno_id_aref) = check_permission($dbh_k_read, 'genotype', 'GenotypeId',
                                                        \@geno_id_list, $group_id, $gadmin_status,
                                                        $LINK_PERM);
  if (!$is_ok) {
    
    my %trouble_itemgroup_id;

    for my $trouble_geno_id (@{$trouble_geno_id_aref}) {

      my $trouble_ig_id = $geno2itemgroup->{$trouble_geno_id};
      $trouble_itemgroup_id{$trouble_ig_id} = 1;
    }

    my @trouble_itemgroup_id_list = keys(%trouble_itemgroup_id);

    my $trouble_itemgroup_id_str = join(',', @trouble_itemgroup_id_list);

    $self->logger->debug("Permission denied: ItemId $trouble_itemgroup_id_str");

    my $err_msg = 'Permission denied: ItemGroupId (' . $trouble_itemgroup_id_str . ')';
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
    return $data_for_postrun_href;
  }

  $dbh_m_read->disconnect();
  $dbh_k_read->disconnect();

  my @sql_set_field;

  my $dbh_m_write = connect_mdb_write();

  my $inserted_id = {};

  $sql  = 'INSERT INTO plate SET ';
  $sql .= 'PlateName=?, ';
  $sql .= 'DateCreated=?, ';
  $sql .= 'OperatorId=?, ';
  $sql .= 'PlateType=?, ';
  $sql .= 'PlateDescription=?, ';
  $sql .= 'StorageId=?, ';
  $sql .= 'PlateWells=?, ';
  $sql .= 'PlateStatus=?';

  my $sth = $dbh_m_write->prepare($sql);
  $sth->execute($PlateName, $DateCreated, $OperatorId, $PlateType,
                $PlateDescription, $StorageId, $PlateWells, $PlateStatus);

  my $plate_id = -1;
  if (!$dbh_m_write->err()) {

    $plate_id = $dbh_m_write->last_insert_id(undef, undef, 'plate', 'PlateId');
    $self->logger->debug("PlateId: $plate_id");
    
    if ( !(defined($inserted_id->{'plate'})) ) {

      $inserted_id->{'plate'} = { 'IdField' => 'PlateId',
                                  'IdValue' => [$plate_id] };
    }
  }
  else {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }
  $sth->finish();

  for my $vcol_id (keys(%{$vcol_data})) {

    my $factor_value = $query->param('VCol_' . "$vcol_id");

    if (length($factor_value) > 0) {

      $sql  = 'INSERT INTO platefactor SET ';
      $sql .= 'PlateId=?, ';
      $sql .= 'FactorId=?, ';
      $sql .= 'FactorValue=?';
      my $factor_sth = $dbh_m_write->prepare($sql);
      $factor_sth->execute($plate_id, $vcol_id, $factor_value);
      
      if ($dbh_m_write->err()) {
        
        my ($rollback_err, $rollback_msg) = rollback_cleanup_multi($self->logger(), $dbh_m_write, $inserted_id);

        if ($rollback_err) {

          $self->logger->debug("Rollback error: $rollback_msg");

          my $err_msg = 'Unexpected Error.';

          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
          
          return $data_for_postrun_href;
        }

        my $err_msg = 'Unexpected Error.';

        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
        return $data_for_postrun_href;
      }

      if ( !(defined($inserted_id->{'platefactor'})) ) {

        $inserted_id->{'platefactor'} = { 'IdField' => 'PlateId',
                                          'IdValue' => [$plate_id] };
      }
    
      $factor_sth->finish();
    }
  } 

  for my $extract_rec (@{$extract_aref}) {

    my $ItemGroupId        = $extract_rec->{'ItemGroupId'};

    my $ParentExtractId = '0';

    if (defined($extract_rec->{'ParentExtractId'})) {

      if ($extract_rec->{'ParentExtractId'} ne '0') {

        $ParentExtractId = $extract_rec->{'ParentExtractId'};
      }
    }

    my $PlateId = '';
 
    if (defined($extract_rec->{'PlateId'})) {

      $PlateId = $extract_rec->{'PlateId'};
    }

    my $GenotypeId = '';

    if (defined($extract_rec->{'GenotypeId'})) {

      $GenotypeId = $extract_rec->{'GenotypeId'};
    }

    my $Tissue = '';

    if (defined($extract_rec->{'Tissue'})) {

      $Tissue = $extract_rec->{'Tissue'};
    }

    my $WellRow = '';

    if (defined($extract_rec->{'WellRow'})) {
    
      $WellRow = $extract_rec->{'WellRow'};
    }

    my $WellCol = '';
    
    if (defined($extract_rec->{'WellCol'})) {
      
      $WellCol = $extract_rec->{'WellCol'};
    }
    
    my $Quality = '';
    
    if (defined($extract_rec->{'Quality'})) {
    
      $Quality = $extract_rec->{'Quality'};
    }

    my $Status = '';

    if (defined($extract_rec->{'Status'})) {

      $Status = $extract_rec->{'Status'};
    }

    $sql  = 'INSERT INTO extract SET ';
    $sql .= 'ParentExtractId=?, ';
    $sql .= 'PlateId=?, ';
    $sql .= 'ItemGroupId=?, ';
    $sql .= 'GenotypeId=?, ';
    $sql .= 'Tissue=?, ';
    $sql .= 'WellRow=?, ';
    $sql .= 'WellCol=?, ';
    $sql .= 'Quality=?, ';
    $sql .= 'Status=?';

    $sth = $dbh_m_write->prepare($sql);
    $sth->execute($ParentExtractId, $plate_id, $ItemGroupId, $GenotypeId,
                  $Tissue, $WellRow, $WellCol, $Quality, $Status);

    my $extract_id = -1;
    if (!$dbh_m_write->err()) {

      $extract_id = $dbh_m_write->last_insert_id(undef, undef, 'extract', 'ExtractId');
      $self->logger->debug("ExtractId: $extract_id");
      
      if ( !(defined($inserted_id->{'extract'})) ) {

        $inserted_id->{'extract'} = { 'IdField' => 'ExtractId',
                                      'IdValue' => [$extract_id] };
      }
      else {

        my $id_val_sofar_aref = $inserted_id->{'extract'}->{'IdValue'};
        push(@{$id_val_sofar_aref}, $extract_id);
        $inserted_id->{'extract'}->{'IdValue'} = $id_val_sofar_aref;
      }
    }
    else {

      $self->logger->debug("SQL err: " . $dbh_m_write->errstr());

      my ($rollback_err, $rollback_msg) = rollback_cleanup_multi($self->logger(), $dbh_m_write, $inserted_id);

      if ($rollback_err) {

        $self->logger->debug("Rollback error: $rollback_msg");

        my $err_msg = 'Unexpected Error.';

        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
          
        return $data_for_postrun_href;
      }

      my $err_msg = 'Unexpected Error.';

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
      return $data_for_postrun_href;
    }
    $sth->finish();
  }

  $dbh_m_write->disconnect();

  my $info_msg_aref = [{'Message' => "Plate ($plate_id) has been added successfully."}];
  my $return_id_aref = [{'Value' => "$plate_id", 'ParaName' => 'PlateId'}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info'     => $info_msg_aref,
                                           'ReturnId' => $return_id_aref,
  };
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub add_plate_runmode {

=pod add_plate_gadmin_HELP_START
{
"OperationName" : "Add plate",
"Description": "Add plate definition to the system for grouping DNA extracts",
"AuthRequired": 1,
"GroupRequired": 1,
"GroupAdminRequired": 0,
"SignatureRequired": 1,
"AccessibleHTTPMethod": [{"MethodName": "POST", "Recommended": 1, "WHEN": "ALWAYS"}, {"MethodName": "GET"}],
"KDDArTModule": "marker",
"KDDArTTable": "plate",
"KDDArTFactorTable": "platefactor",
"SuccessMessageXML": "<?xml version='1.0' encoding='UTF-8'?><DATA><ReturnId Value='10' ParaName='PlateId' /><Info Message='Plate (10) has been added successfully.' /></DATA>",
"SuccessMessageJSON": "{'ReturnId' : [{'Value' : '11','ParaName' : 'PlateId'}], 'Info' : [{'Message' : 'Plate (11) has been added successfully.'}]}",
"ErrorMessageXML": [{"IdNotFound": "<?xml version='1.0' encoding='UTF-8'?><DATA><Error PlateType='PlateType (251) not found.' /></DATA>"}],
"ErrorMessageJSON": [{"IdNotFound": "{'Error' : [{'PlateType' : 'PlateType (251) not found.'}]}"}],
"HTTPReturnedErrorCode": [{"HTTPCode": 420}]
}
=cut

  my $self  = shift;
  my $query = $self->query();

  my $data_for_postrun_href = {};

  # Generic required static field checking

  my $dbh_read = connect_mdb_read();

  my $skip_field = {'DateCreated' => 1};

  my ($get_scol_err, $get_scol_msg, $scol_data, $pkey_data) = get_static_field($dbh_read, 'plate');

  if ($get_scol_err) {

    $self->logger->debug("Get static field info failed: $get_scol_msg");
    
    my $err_msg = "Unexpected Error.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $required_field_href = {};

  for my $static_field (@{$scol_data}) {

    my $field_name = $static_field->{'Name'};
    
    if ($skip_field->{$field_name}) { next; }

    if ($static_field->{'Required'} == 1) {

      $required_field_href->{$field_name} = $query->param($field_name);
    }
  }

  $dbh_read->disconnect();

  my ($missing_err, $missing_href) = check_missing_href( $required_field_href );

  if ($missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$missing_href]};

    return $data_for_postrun_href;
  }

  # Finish generic required static field checking

  my $PlateName        = $query->param('PlateName');
  my $OperatorId       = $query->param('OperatorId');

  my $PlateType        = '0';

  if (defined($query->param('PlateType'))) {

    if (length($query->param('PlateType')) > 0) {

      $PlateType = $query->param('PlateType');
    }
  }
  
  my $PlateDescription = '';

  if (defined($query->param('PlateDescription'))) {

    $PlateDescription = $query->param('PlateDescription');
  }

  my $StorageId        = '0';

  if (defined($query->param('StorageId'))) {

    if (length($query->param('StorageId')) > 0) {

      $StorageId = $query->param('StorageId');
    }
  }

  my $PlateWells       = '';

  if (defined($query->param('PlateWells'))) {

    $PlateWells = $query->param('PlateWells');
  }

  my $PlateStatus      = '';

  if (defined($query->param('PlateStatus'))) {

    $PlateStatus = $query->param('PlateStatus');
  }

  my $dbh_k_read = connect_kdb_read();

  if (length($PlateWells) > 0) {

    my ($int_err, $int_href) = check_integer_href( {'PlateWells' => $PlateWells} );

    if ($int_err) {

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [$int_href]};
      
      return $data_for_postrun_href;
    }
  }
    
  $self->logger->debug("Plate name: $PlateName");

  my $sql = "SELECT FactorId, CanFactorHaveNull, FactorValueMaxLength ";
  $sql   .= "FROM factor ";
  $sql   .= "WHERE TableNameOfFactor='platefactor'";

  my $vcol_data = $dbh_k_read->selectall_hashref($sql, 'FactorId');

  my $vcol_param_data = {};
  my $vcol_len_info   = {};
  my $vcol_param_data_maxlen = {};
  for my $vcol_id (keys(%{$vcol_data})) {

    my $vcol_param_name = "VCol_${vcol_id}";
    my $vcol_value      = $query->param($vcol_param_name);
    if ($vcol_data->{$vcol_id}->{'CanFactorHaveNull'} != 1) {

      $vcol_param_data->{$vcol_param_name} = $vcol_value;
    }

    $vcol_len_info->{$vcol_param_name} = $vcol_data->{$vcol_id}->{'FactorValueMaxLength'};
    $vcol_param_data_maxlen->{$vcol_param_name} = $vcol_value;
  }

  my ($vcol_missing_err, $vcol_missing_href) = check_missing_href( $vcol_param_data );

  if ($vcol_missing_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_missing_href]};

    return $data_for_postrun_href;
  }

  my ($vcol_maxlen_err, $vcol_maxlen_href) = check_maxlen_href($vcol_param_data_maxlen, $vcol_len_info);

  if ($vcol_maxlen_err) {

    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [$vcol_maxlen_href]};

    return $data_for_postrun_href;
  }

  if (!record_existence($dbh_k_read, 'systemuser', 'UserId', $OperatorId)) {

    my $err_msg = "OperatorId ($OperatorId) not found.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
    
    return $data_for_postrun_href;
  }

  if ($PlateType ne '0') {

    if (!type_existence($dbh_k_read, 'plate', $PlateType)) {

      my $err_msg = "PlateType ($PlateType) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateType' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  if ($StorageId ne '0') {

    if ( !record_existence($dbh_k_read, 'storage', 'StorageId', $StorageId) ) {

      my $err_msg = "StorageId ($StorageId) not found.";
      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }
  }

  my $dbh_m_read = connect_mdb_read();

  if (record_existence($dbh_m_read, 'plate', 'PlateName', $PlateName)) {

    my $err_msg = " ($PlateName) already exists.";
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'PlateName' => $err_msg}]};

    return $data_for_postrun_href;
  }

  my $cur_dt = DateTime->now( time_zone => $TIMEZONE );
  $cur_dt = DateTime::Format::MySQL->format_datetime($cur_dt);

  my $DateCreated = $cur_dt;

  my $extract_xml_file = $self->authen->get_upload_file();
  my $extract_dtd_file = $self->get_extract_dtd_file();

  add_dtd($extract_dtd_file, $extract_xml_file);

  $self->logger->debug("Extract XML file: $extract_xml_file");

  my $xml_checker_parser = new XML::Checker::Parser( Handlers => { } );

  eval {

    local $XML::Checker::FAIL = sub {
      
      my $code = shift;
      my $err_str = XML::Checker::error_string ($code, @_);
      $self->logger->debug("XML Parsing ERR: $code : $err_str");
      die $err_str;
    };
    $xml_checker_parser->parsefile($extract_xml_file);
  };

  if ($@) {

    my $err_msg = $@;
    $self->logger->debug("Parsing XML error: $err_msg");
    my $user_err_msg = "Extract xml file does not comply with its definition.\n";
    $user_err_msg   .= "Details: $err_msg";

    $data_for_postrun_href->{'Error'}       = 1;
    $data_for_postrun_href->{'Data'}        = {'Error' => [{'Message' => $user_err_msg}]};

    return $data_for_postrun_href;
  }

  my $extract_xml  = read_file($extract_xml_file);
  my $extract_aref = xml2arrayref($extract_xml, 'extract');

  my $uniq_well_href  = {};
  my $uniq_extract_id = {};

  for my $extract_rec (@{$extract_aref}) {

    my $extract_id = $extract_rec->{'ExtractId'};

    if (!record_existence($dbh_m_read, 'extract', 'ExtractId', $extract_id)) {

      my $err_msg = "Extract ($extract_id) not found.";
      $data_for_postrun_href->{'Error'}       = 1;
      $data_for_postrun_href->{'Data'}        = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }

    my $plate_id = read_cell_value($dbh_m_read, 'extract', 'PlateId', 'ExtractId', $extract_id);

    if (length($plate_id) > 0) {

      if ($plate_id != 0) {

        my $err_msg = "Extract ($extract_id) has a plate assigned already.";
        $data_for_postrun_href->{'Error'}       = 1;
        $data_for_postrun_href->{'Data'}        = {'Error' => [{'Message' => $err_msg}]};

        return $data_for_postrun_href;
      }
    }

    $sql = 'SELECT CONCAT(WellRow,WellCol) AS Well FROM extract WHERE ExtractId=?';

    my ($read_well_err, $well) = read_cell($dbh_m_read, $sql, [$extract_id]);
    
    if (defined($uniq_well_href->{$well})) {

      my $dup_well_extract_id = $uniq_well_href->{$well};

      my $err_msg = "Extract ($extract_id) and extract ($dup_well_extract_id) have the same well position ($well).";
      $data_for_postrun_href->{'Error'}       = 1;
      $data_for_postrun_href->{'Data'}        = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }
    else {

      $uniq_well_href->{$well} = $extract_id;
    }

    if (defined($uniq_extract_id->{$extract_id})) {
      
      my $err_msg = "Extract ($extract_id): duplicate.";
      $data_for_postrun_href->{'Error'}       = 1;
      $data_for_postrun_href->{'Data'}        = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }
    else {

      $uniq_extract_id->{$extract_id} = 1;
    }
  }

  $dbh_m_read->disconnect();
  $dbh_k_read->disconnect();

  my @sql_set_field;

  my $dbh_m_write = connect_mdb_write();

  my $inserted_id = {};

  $sql  = 'INSERT INTO plate SET ';
  $sql .= 'PlateName=?, ';
  $sql .= 'DateCreated=?, ';
  $sql .= 'OperatorId=?, ';
  $sql .= 'PlateType=?, ';
  $sql .= 'PlateDescription=?, ';
  $sql .= 'StorageId=?, ';
  $sql .= 'PlateWells=?, ';
  $sql .= 'PlateStatus=?';

  my $sth = $dbh_m_write->prepare($sql);
  $sth->execute($PlateName, $DateCreated, $OperatorId, $PlateType,
                $PlateDescription, $StorageId, $PlateWells, $PlateStatus);

  my $plate_id = -1;
  if (!$dbh_m_write->err()) {

    $plate_id = $dbh_m_write->last_insert_id(undef, undef, 'plate', 'PlateId');
    $self->logger->debug("PlateId: $plate_id");
    
    if ( !(defined($inserted_id->{'plate'})) ) {

      $inserted_id->{'plate'} = { 'IdField' => 'PlateId',
                                  'IdValue' => [$plate_id] };
    }
  }
  else {

    $self->logger->debug("Insert into plate failed");
    $data_for_postrun_href->{'Error'} = 1;
    $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => 'Unexpected error.'}]};

    return $data_for_postrun_href;
  }
  $sth->finish();

  for my $vcol_id (keys(%{$vcol_data})) {

    my $factor_value = $query->param('VCol_' . "$vcol_id");

    if (length($factor_value) > 0) {

      $sql  = 'INSERT INTO platefactor SET ';
      $sql .= 'PlateId=?, ';
      $sql .= 'FactorId=?, ';
      $sql .= 'FactorValue=?';
      my $factor_sth = $dbh_m_write->prepare($sql);
      $factor_sth->execute($plate_id, $vcol_id, $factor_value);
      
      if ($dbh_m_write->err()) {
        
        my ($rollback_err, $rollback_msg) = rollback_cleanup_multi($self->logger(), $dbh_m_write, $inserted_id);

        if ($rollback_err) {

          $self->logger->debug("Rollback error: $rollback_msg");

          my $err_msg = 'Unexpected Error.';

          $data_for_postrun_href->{'Error'} = 1;
          $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
          
          return $data_for_postrun_href;
        }

        $self->logger->debug("Insert into platefactor failed");
        my $err_msg = 'Unexpected Error.';

        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};
      
        return $data_for_postrun_href;
      }

      if ( !(defined($inserted_id->{'platefactor'})) ) {

        $inserted_id->{'platefactor'} = { 'IdField' => 'PlateId',
                                          'IdValue' => [$plate_id] };
      }
    
      $factor_sth->finish();
    }
  }

  if (scalar(keys(%{$uniq_extract_id})) > 0) {

    my $extract_id_csv = join(',', keys(%{$uniq_extract_id}));

    $sql  = 'UPDATE extract SET ';
    $sql .= 'PlateId=? ';
    $sql .= "WHERE ExtractId IN ($extract_id_csv)";

    $sth = $dbh_m_write->prepare($sql);
    $sth->execute($plate_id);

    if ($dbh_m_write->err()) {

      my ($rollback_err, $rollback_msg) = rollback_cleanup_multi($self->logger(), $dbh_m_write, $inserted_id);

      if ($rollback_err) {

        $self->logger->debug("Rollback error: $rollback_msg");

        my $err_msg = 'Unexpected Error.';

        $data_for_postrun_href->{'Error'} = 1;
        $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

        return $data_for_postrun_href;
      }

      $self->logger->debug("Update extract failed");
      my $err_msg = 'Unexpected Error.';

      $data_for_postrun_href->{'Error'} = 1;
      $data_for_postrun_href->{'Data'}  = {'Error' => [{'Message' => $err_msg}]};

      return $data_for_postrun_href;
    }
    $sth->finish();
  }

  $dbh_m_write->disconnect();

  my $info_msg_aref = [{'Message' => "Plate ($plate_id) has been added successfully."}];
  my $return_id_aref = [{'Value' => "$plate_id", 'ParaName' => 'PlateId'}];

  $data_for_postrun_href->{'Error'}     = 0;
  $data_for_postrun_href->{'Data'}      = {'Info'     => $info_msg_aref,
                                           'ReturnId' => $return_id_aref,
  };
  $data_for_postrun_href->{'ExtraData'} = 0;

  return $data_for_postrun_href;
}

sub get_extract_dtd_file {

  my $dtd_path = $DTD_PATH;

  return "${dtd_path}/extract.dtd";
}

sub get_extract_all_field_dtd_file {

  my $dtd_path = $DTD_PATH;

  return "${dtd_path}/extract_all_field.dtd";
}

sub get_analysisgroup_dtd_file {

  my $dtd_path = $DTD_PATH;

  return "${dtd_path}/analysisgroup.dtd";
}

sub _set_error {

  my ( $self, $error_message ) = @_;
  return {
    'Error' => 1,
    'Data'  => { 'Error' => [ { 'Message' => $error_message || 'Unexpected error.' } ] }
  };
}

1;