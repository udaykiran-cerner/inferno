# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore301ProcedureSequence < SequenceBase
      title 'Procedure Tests'

      description 'Verify that Procedure resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'USCPROC'

      requires :token, :patient_id
      conformance_supports :Procedure

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'date'
          value_found = can_resolve_path(resource, 'occurrenceDateTime') do |date|
            validate_date_search(value, date)
          end
          assert value_found, 'date on resource does not match date requested'

        when 'code'
          value_found = can_resolve_path(resource, 'code.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'code on resource does not match code requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.

      )

      @resources_found = false

      test 'Server rejects Procedure search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
          )
          versions :r4
        end

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Procedure search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @procedure = reply&.resource&.entry&.first&.resource
        @procedure_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Procedure'), reply)
        save_delayed_sequence_references(@procedure)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
      end

      test 'Server returns expected results from Procedure search by patient+date' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'

        patient_val = @instance.patient_id
        date_val = get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'occurrenceDateTime'))
        search_params = { 'patient': patient_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Procedure search by patient+code+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'

        patient_val = @instance.patient_id
        code_val = get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'code'))
        date_val = get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'occurrenceDateTime'))
        search_params = { 'patient': patient_val, 'code': code_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Procedure search by patient+status' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'

        patient_val = @instance.patient_id
        status_val = get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'status'))
        search_params = { 'patient': patient_val, 'status': status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Procedure read resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test 'Procedure vread resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test 'Procedure history resource supported' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Procedure resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Procedure')
      end

      test 'At least one of every must support element is provided in any Procedure for this patient.' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @procedure_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Procedure.status',
          'Procedure.code',
          'Procedure.subject',
          'Procedure.performedDateTime',
          'Procedure.performedPeriod'
        ]
        must_support_elements.each do |path|
          @procedure_ary&.each do |resource|
            truncated_path = path.gsub('Procedure.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @procedure_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Procedure resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '12'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@procedure)
      end
    end
  end
end
