module FV
  class ApiError < RuntimeError
    ERRORS = {
      100 => 'ValidationError',
      101 => 'InvalidResourceError',
      102 => 'FilterNotAllowedError',
      103 => 'InvalidFieldValueError',
      104 => 'InvalidFieldError',
      105 => 'ParamNotAllowedError',
      106 => 'ParamMissingError',
      107 => 'InvalidFilterValueError',
      108 => 'CountMismatchError',
      109 => 'KeyOrderMismatchError',
      110 => 'KeyNotIncludedInURLError',
      112 => 'InvalidIncludeError',
      113 => 'RelationExistsError',
      114 => 'InvalidSortCriteriaError',
      115 => 'InvalidLinksObjectError',
      116 => 'TypeMismatchError',
      117 => 'InvalidPageObjectError',
      118 => 'InvalidPageValueError',
      119 => 'InvalidFieldFormatError',
      120 => 'InvalidFiltersSyntaxError',
      121 => 'SaveFailedError',
      401 => 'AuthenticationError',
      403 => 'ForbiddenError',
      404 => 'RecordNotFoundError',
      406 => 'NotAcceptableError',
      415 => 'UnsupportedMediaTypeError',
      422 => 'UnprocessableEntity',
      423 => 'LockedError',
      500 => 'InternalServerError'
    }.freeze

    def self.from_raw(raw)
      FV.const_get(ERRORS.fetch(raw['code'].to_i)).new(raw)
    rescue KeyError
      raise ArgumentError, "Error code: #{raw['code'].inspect} is not defined"
    end

    def initialize(raw_error)
      @raw_error = raw_error
    end

    def code
      @raw_error['code'].to_i
    end

    def detail
      @raw_error['detail']
    end

    def title
      @raw_error['title']
    end

    def status
      @raw_error['status'].to_i
    end

    def source
      @raw_error['source']
    end

    def message
      "#{title}: #{detail}"
    end
  end

  class TimeoutError < ApiError
    def initialize
      @raw_error = {
        'code' => 503,
        'title' => 'Server Timeout',
        'detail' => 'The server could not be reached',
        'status' => 503
      }
    end
  end

  class ValidationError < ApiError; end # code: 100
  class InvalidResourceError < ApiError; end # code: 101
  class FilterNotAllowedError < ApiError; end # code: 102
  class InvalidFieldValueError < ApiError; end # code: 103
  class InvalidFieldError < ApiError; end # code: 104
  class ParamNotAllowedError < ApiError; end # code: 105
  class ParamMissingError < ApiError; end # code: 106
  class InvalidFilterValueError < ApiError; end # code: 107
  class CountMismatchError < ApiError; end # code: 108
  class KeyOrderMismatchError < ApiError; end # code: 109
  class KeyNotIncludedInURLError < ApiError; end # code: 110
  class InvalidIncludeError < ApiError; end # code: 112
  class RelationExistsError < ApiError; end # code: 113
  class InvalidSortCriteriaError < ApiError; end # code: 114
  class InvalidLinksObjectError < ApiError; end # code: 115
  class TypeMismatchError < ApiError; end # code: 116
  class InvalidPageObjectError < ApiError; end # code: 117
  class InvalidPageValueError < ApiError; end # code: 118
  class InvalidFieldFormatError < ApiError; end # code: 119
  class InvalidFiltersSyntaxError < ApiError; end # code: 120
  class SaveFailedError < ApiError; end # code: 121
  class AuthenticationError < ApiError; end # code: 401
  class ForbiddenError < ApiError; end # code: 403
  class RecordNotFoundError < ApiError; end # code: 404
  class NotAcceptableError < ApiError; end # code: 406
  class UnsupportedMediaTypeError < ApiError; end # code: 415
  class UnprocessableEntity < ApiError; end # code: 422
  class LockedError < ApiError; end # code: 423
  class InternalServerError < ApiError; end # code: 500

  class InvalidConfigurationError < RuntimeError; end
  class UnknownResponseError < RuntimeError; end
end
